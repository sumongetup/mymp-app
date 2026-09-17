/// Member search that answers in Bangla or English, however the name is spelt.
///
/// Readers type "tarek", "Tarique", "তারেক" or "tareq rahman" and expect the
/// same person; the secretariat itself writes one man "Hossain" and the next
/// "Hussain". So every name is also reduced to its consonant sounds in one
/// shared Latin alphabet ("তারেক" and "Tarique" both become t-r-k), and a word
/// matches when its letters or its sounds agree. Seats and districts match in
/// either script and with either digits ("dhaka 17", "ঢাকা-১৭"), and a seat's
/// upazilas find its member.
library;

import 'models.dart';

const _bnDigits = '০১২৩৪৫৬৭৮৯';

/// Bengali digits to ASCII, lower case, punctuation to spaces.
String _plain(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final d = _bnDigits.indexOf(ch);
    if (d >= 0) {
      b.write(d);
    } else if (RegExp(
      r'[.,\-_/()\[\]:;!?"'
      "'"
      r'`’‘“”]',
    ).hasMatch(ch)) {
      b.write(' ');
    } else {
      b.write(ch);
    }
  }
  return b.toString();
}

/// Spelling a Bengali reader will not think about: the two ই, the two উ, ণ and
/// ন, the three স, ৎ and ত, the nukta, the joiners.
String _foldBn(String s) => s
    .replaceAll('\u200c', '')
    .replaceAll('\u200d', '')
    // ড় ঢ় য় arrive both precomposed and as letter plus nukta.
    .replaceAll('\u09a1\u09bc', 'র')
    .replaceAll('\u09dc', 'র')
    .replaceAll('\u09a2\u09bc', 'র')
    .replaceAll('\u09dd', 'র')
    .replaceAll('\u09af\u09bc', '\u09df')
    .replaceAll('\u09bc', '')
    .replaceAll('ী', 'ি')
    .replaceAll('ূ', 'ু')
    .replaceAll('ণ', 'ন')
    .replaceAll('ষ', 'স')
    .replaceAll('শ', 'স')
    .replaceAll('ৎ', 'ত');

const _bnSound = {
  'ক': 'k', 'খ': 'k', 'গ': 'g', 'ঘ': 'g', 'ঙ': 'n', //
  'চ': 'c', 'ছ': 'c', 'জ': 'j', 'ঝ': 'j', 'ঞ': 'n', //
  'ট': 't', 'ঠ': 't', 'ড': 'd', 'ঢ': 'd', 'ণ': 'n', //
  'ত': 't', 'থ': 't', 'দ': 'd', 'ধ': 'd', 'ন': 'n', //
  'প': 'p', 'ফ': 'f', 'ব': 'b', 'ভ': 'b', 'ম': 'm', //
  'য': 'j', 'র': 'r', 'ল': 'l', 'শ': 's', 'ষ': 's', //
  'স': 's', 'হ': 'h', 'ৎ': 't', 'ং': 'n', //
};

/// A Bengali word's consonant sounds: "রহমান" is r-h-m-n. The য of a যফলা
/// ("ব্যারিস্টার") and য় (left unmapped) are vowels, as in English spelling,
/// and a বফলা ("স্বরাষ্ট্র") is not heard.
String _skeletonBn(String word) {
  final b = StringBuffer();
  final chars = word.runes.map(String.fromCharCode).toList();
  for (var i = 0; i < chars.length; i++) {
    final ch = chars[i];
    if ((ch == 'য' || ch == 'ব') && i > 0 && chars[i - 1] == '্') continue;
    final s = _bnSound[ch];
    if (s != null) b.write(s);
  }
  return _collapse(b.toString());
}

/// An English word's consonant sounds, spelt the way the Bengali ones are:
/// "Tarique" and "Tareq" are t-r-k, "Chowdhury" is c-d-r, "Zamir" is j-m-r.
String _skeletonEn(String word) {
  var w = word
      .replaceAll('ph', 'f')
      .replaceAll('ck', 'k')
      .replaceAll('qu', 'k')
      .replaceAll('q', 'k')
      .replaceAll('x', 'ks')
      .replaceAll('z', 'j')
      .replaceAll('v', 'b');
  // "ch" is one sound; any other c is a k.
  w = w.replaceAll('ch', '#').replaceAll('c', 'k').replaceAll('#', 'c');
  final b = StringBuffer();
  const vowels = 'aeiouwy';
  String prev = '';
  for (final r in w.runes) {
    final ch = String.fromCharCode(r);
    if (!RegExp(r'[a-z]').hasMatch(ch)) continue;
    // An h after a consonant only colours it (kh, dh, sh, bh), as in Bengali
    // spelling, where খ, ধ, শ and ভ carry no separate h.
    if (ch == 'h' && prev.isNotEmpty && !vowels.contains(prev)) {
      prev = ch;
      continue;
    }
    if (!vowels.contains(ch)) b.write(ch);
    prev = ch;
  }
  var out = b.toString();
  // A final h is silent: "Miah" is "Mia".
  if (out.endsWith('h') && word.endsWith('h')) {
    out = out.substring(0, out.length - 1);
  }
  return _collapse(out);
}

String _collapse(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (b.isEmpty || !b.toString().endsWith(ch)) b.write(ch);
  }
  return b.toString();
}

final _bengali = RegExp(r'[\u0980-\u09FF]');
final _number = RegExp(r'^\d+$');

class _Word {
  final String text;
  final String sound;
  const _Word(this.text, this.sound);
}

List<_Word> _words(String? s) {
  if (s == null || s.trim().isEmpty) return const [];
  final out = <_Word>[];
  for (final raw in _plain(s).split(RegExp(r'\s+'))) {
    if (raw.isEmpty) continue;
    final bn = _bengali.hasMatch(raw);
    // A hasanta is spelling, not sound, once the যফলা has been read.
    final text = bn ? _foldBn(raw).replaceAll('্', '') : raw;
    final sound = _number.hasMatch(raw)
        ? raw
        : bn
        ? _skeletonBn(_foldBn(raw))
        : _skeletonEn(raw);
    out.add(_Word(text, sound));
  }
  return out;
}

/// Titles people type or leave out: a query "md tarek" means "tarek".
const _titles = {
  'md',
  'mohammad',
  'mohammed',
  'muhammad',
  'mohd',
  'mst',
  'most',
  'mosammat', //
  'dr', 'barrister', 'adv', 'advocate', 'alhaj', 'alhajj', 'engr', 'prof', //
  'মো', 'মোঃ', 'মোহাম্মদ', 'মুহাম্মদ', 'মোছাঃ', 'মোসাম্মত', 'ডা', 'ডাঃ', 'ড', //
  'ব্যারিস্টার',
  'ব্যারিষ্টার',
  'অ্যাডভোকেট',
  'এডভোকেট',
  'আলহাজ্ব',
  'আলহাজ',
  'অধ্যাপক',
};

final _titleTexts = {for (final t in _titles) ..._words(t).map((w) => w.text)};

int _editDistance(String a, String b, int limit) {
  if ((a.length - b.length).abs() > limit) return limit + 1;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    var best = cur[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [
        prev[j] + 1,
        cur[j - 1] + 1,
        prev[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
      if (cur[j] < best) best = cur[j];
    }
    if (best > limit) return limit + 1;
    prev = cur;
  }
  return prev[b.length];
}

/// How close two spellings in the same script are, 0 to 1.
double _likeness(String a, String b) {
  final longest = a.length > b.length ? a.length : b.length;
  if (longest == 0) return 0;
  final d = _editDistance(a, b, longest);
  return 1 - d / longest;
}

/// How well one typed word fits one word of a field: letters first, sounds
/// next, a slip of one sound last. Among sound-alikes the nearer spelling wins.
double _fit(_Word q, _Word w) {
  if (_number.hasMatch(q.text)) return q.text == w.text ? 4 : 0;
  if (w.text == q.text) return 4;
  if (w.text.startsWith(q.text)) return q.text.length >= 2 ? 3 : 1.5;
  if (q.sound.isEmpty || w.sound.isEmpty) return 0;
  final sameScript = _bengali.hasMatch(q.text) == _bengali.hasMatch(w.text);
  final near = sameScript ? _likeness(q.text, w.text) * 0.4 : 0.2;
  if (w.sound == q.sound) return (q.sound.length >= 2 ? 2.4 : 1) + near;
  if (q.sound.length >= 3 && w.sound.startsWith(q.sound)) return 1.7 + near;
  // One slipped sound in a longer word, but never the first: "safiqur" may
  // find "Shafiqul", "srstr" must not find "brstr".
  if (q.sound.length >= 4 && q.sound[0] == w.sound[0]) {
    final limit = q.sound.length >= 7 ? 2 : 1;
    if (_editDistance(q.sound, w.sound, limit) <= limit) return 1.1 + near;
  }
  return 0;
}

class _Field {
  final List<_Word> words;
  final double weight;
  const _Field(this.words, this.weight);
}

class _Indexed {
  final MemberBrief member;
  final List<_Field> fields;
  const _Indexed(this.member, this.fields);
}

/// The member list, indexed once, searched on every keystroke.
class MemberSearch {
  final List<_Indexed> _index;

  MemberSearch(
    List<MemberBrief> members, {
    Map<String, String> partyNames = const {},
  }) : _index = [
         for (final m in members)
           _Indexed(m, [
             _Field(_words('${m.nameBn} ${m.nameEn ?? ''}'), 1.5),
             _Field(
               _words(
                 '${m.seatBn ?? ''} ${m.seatEn ?? ''} ${m.districtBn ?? ''} ${m.districtEn ?? ''}',
               ),
               1.2,
             ),
             _Field(
               _words(
                 '${m.partyBn ?? ''} ${m.party ?? ''} ${partyNames[m.party] ?? ''} ${m.officeBn ?? ''}',
               ),
               0.8,
             ),
             _Field(
               _words(
                 m.areaBn,
               ).where((w) => !_number.hasMatch(w.text)).toList(),
               0.5,
             ),
           ]),
       ];

  /// Everyone who matches every typed word, best first; ties keep [members]'
  /// order. An empty query returns nothing: the caller shows the full list.
  List<MemberBrief> search(String query) {
    var words = _words(query);
    final meaningful = words
        .where((w) => !_titleTexts.contains(w.text))
        .toList();
    if (meaningful.isNotEmpty) words = meaningful;
    if (words.isEmpty) return const [];

    final scored = <(MemberBrief, double, int)>[];
    for (final (i, entry) in _index.indexed) {
      var total = 0.0;
      var all = true;
      for (final q in words) {
        var best = 0.0;
        for (final f in entry.fields) {
          for (final w in f.words) {
            final s = _fit(q, w) * f.weight;
            if (s > best) best = s;
          }
        }
        if (best == 0) {
          all = false;
          break;
        }
        total += best;
      }
      if (all) scored.add((entry.member, total, i));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$3.compareTo(b.$3);
    });
    // Keep strong matches when there are some: a sound-alike should not bury
    // the member whose name was typed exactly.
    if (scored.isNotEmpty) {
      final top = scored.first.$2;
      return [
        for (final s in scored)
          if (s.$2 >= top * 0.5) s.$1,
      ];
    }
    return const [];
  }
}
