import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Everything the app knows comes from here, and it is all public: no account,
/// no key, nothing sent up. The only thing stored on the phone is a copy of
/// what was fetched, so the app opens with content on a train with no signal.
class Api {
  Api._();
  static final Api instance = Api._();

  static const base = 'https://mymp.bd';
  static const _userAgent = 'mymp-app/1.0 (Android; +https://mymp.bd)';

  Bootstrap? _bootstrap;

  // Renamed when the list gains a field: a copy saved by an older version
  // lacks it and would stand until the site's data next changed.
  static const _bootstrapKey = 'bootstrap_v3';
  Bootstrap? get cached => _bootstrap;

  final _memberCache = <String, MemberDetail>{};

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final http.Response res;
    try {
      res = await http
          .get(
            Uri.parse('$base$path'),
            headers: const {
              'accept': 'application/json',
              'user-agent': _userAgent,
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw ApiException(
        'সংযোগ খুব ধীর, সময়মতো উত্তর আসেনি। একটু পরে আবার চেষ্টা করুন।',
      );
    } catch (_) {
      // No signal, no data plan, or the site unreachable: the reader cannot
      // act on a socket error's English text, only on what it means.
      throw ApiException(
        'ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না। সংযোগ দেখে আবার চেষ্টা করুন।',
      );
    }
    if (res.statusCode == 404) {
      throw ApiException('এই তথ্যটি এখন আর পাওয়া যাচ্ছে না।');
    }
    if (res.statusCode != 200) {
      throw ApiException(
        'সার্ভার এই মুহূর্তে সাড়া দিচ্ছে না। একটু পরে আবার চেষ্টা করুন।',
      );
    }
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('তথ্য পড়া গেল না। একটু পরে আবার চেষ্টা করুন।');
    }
  }

  /// The member list, from the phone first and the network second.
  ///
  /// The stored copy is shown immediately even when it is old, and replaced
  /// quietly once the fetch returns; a slow connection then costs the reader
  /// nothing. [force] skips the stored copy, for pull-to-refresh.
  Future<Bootstrap> loadBootstrap({bool force = false}) {
    if (_bootstrap != null && !force) return Future.value(_bootstrap!);
    // Several tabs ask at launch; they share the one request.
    if (!force && _loading != null) return _loading!;
    final loading = _loadBootstrap(force);
    if (!force) {
      _loading = loading;
      loading.whenComplete(() => _loading = null).ignore();
    }
    return loading;
  }

  Future<Bootstrap>? _loading;

  Future<Bootstrap> _loadBootstrap(bool force) async {
    final prefs = await SharedPreferences.getInstance();
    // Copies saved under older keys are never read again.
    for (final old in const ['bootstrap', 'bootstrap_v2']) {
      if (prefs.containsKey(old)) unawaited(prefs.remove(old));
    }
    if (!force) {
      final saved = prefs.getString(_bootstrapKey);
      if (saved != null) {
        try {
          _bootstrap = Bootstrap.fromJson(
            jsonDecode(saved) as Map<String, dynamic>,
          );
          unawaited(_refreshBootstrap(prefs));
          return _bootstrap!;
        } catch (_) {
          await prefs.remove(_bootstrapKey);
        }
      }
    }

    final json = await _getJson('/api/app/v1/bootstrap');
    await prefs.setString(_bootstrapKey, jsonEncode(json));
    _bootstrap = Bootstrap.fromJson(json);
    return _bootstrap!;
  }

  /// Fetched behind a shown-from-storage list; a failure here changes nothing.
  Future<void> _refreshBootstrap(SharedPreferences prefs) async {
    try {
      final json = await _getJson('/api/app/v1/bootstrap');
      final fresh = Bootstrap.fromJson(json);
      if (fresh.version != _bootstrap?.version && fresh.members.isNotEmpty) {
        await prefs.setString(_bootstrapKey, jsonEncode(json));
        _bootstrap = fresh;
        onBootstrapUpdated?.call(fresh);
      }
    } catch (_) {
      // Offline, or the site is being deployed. The stored copy stands.
    }
  }

  /// Set by the shell so a quiet refresh can redraw the list it is showing.
  void Function(Bootstrap)? onBootstrapUpdated;

  Future<MemberDetail> member(String slug) async {
    final held = _memberCache[slug];
    if (held != null) return held;
    final json = await _getJson('/api/app/v1/mp/$slug');
    final detail = MemberDetail.fromJson(json);
    _memberCache[slug] = detail;
    return detail;
  }

  Future<AdviserDetail> adviser(String slug) async {
    final json = await _getJson('/api/app/v1/adviser/$slug');
    return AdviserDetail.fromJson(json);
  }

  Future<List<CabinetPost>> cabinet() async {
    final json = await _getJson('/api/app/v1/cabinet');
    return (json['posts'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CabinetPost.fromJson)
        .toList();
  }

  Map<String, dynamic>? _election;

  /// The election and the House it produced; kept for the session once read.
  Future<Map<String, dynamic>> election() async {
    return _election ??= await _getJson('/api/app/v1/election');
  }

  Future<List<Story>> news({String? type, int limit = 200}) async {
    final query = StringBuffer('?limit=$limit');
    if (type != null) query.write('&type=$type');
    final json = await _getJson('/api/app/v1/news$query');
    return (json['stories'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Story.fromJson)
        .toList();
  }

  /// One member's own news and videos, from the same route the website's
  /// profile page reads.
  Future<List<Story>> memberFeed(String slug) async {
    // The newest 60 whatever their month: the plain route sends only this
    // month, and a member whose news was all from February showed nothing.
    final json = await _getJson('/api/feed/$slug?recent=60');
    final items = <Story>[];
    for (final key in const ['pinned', 'items']) {
      for (final raw
          in (json[key] as List? ?? []).whereType<Map<String, dynamic>>()) {
        items.add(feedEntryToStory(raw));
      }
    }
    return items;
  }

  /// The member feed answers in the website's own shape; this is the one place
  /// that knows the difference.
  static Story feedEntryToStory(Map<String, dynamic> j) {
    final published = j['publishedAt'] as String? ?? '';
    return Story(
      id: 'feed-${j['id']}',
      date: published.length >= 10 ? published.substring(0, 10) : published,
      dateLabel: '',
      lead: StoryLink(
        title: j['title'] as String? ?? '',
        source: j['outletName'] as String? ?? '',
        url: j['url'] as String? ?? '',
      ),
      kind: j['type'] as String? ?? 'news',
      thumbnail: j['thumbnailUrl'] as String?,
      durationSeconds: (j['durationSeconds'] as num?)?.toInt(),
    );
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
