import 'package:flutter/material.dart';

import '../api.dart';
import '../bn.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'member_screen.dart';

/// The list every reader opens first: all 348 members, searchable by name, by
/// seat and by district, filterable by party.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _search = TextEditingController();
  late Future<Bootstrap> _future;
  String _query = '';
  String? _party;
  String? _district;

  @override
  void initState() {
    super.initState();
    _future = Api.instance.loadBootstrap();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final fresh = Api.instance.loadBootstrap(force: true);
    setState(() => _future = fresh);
    await fresh;
  }

  /// Matching folds the spellings a reader will not think about: ৎ and ত, the
  /// two ই, the two উ, and the hasanta, so "শফিকুর" finds "শফিকুর" however the
  /// secretariat typed it.
  static String _fold(String s) => s
      .replaceAll('্', '')
      .replaceAll('ী', 'ি')
      .replaceAll('ূ', 'ু')
      .replaceAll('ণ', 'ন')
      .replaceAll('ষ', 'স')
      .replaceAll('শ', 'স')
      .replaceAll('ৎ', 'ত')
      .replaceAll('়', '')
      .toLowerCase();

  List<MemberBrief> _filter(List<MemberBrief> all) {
    final words = _fold(_query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return all.where((m) {
      if (_party != null && m.party != _party) return false;
      if (_district != null && m.districtBn != _district) return false;
      if (words.isEmpty) return true;
      final hay = _fold('${m.nameBn} ${m.nameEn ?? ''} ${m.seatBn ?? ''} ${m.districtBn ?? ''} ${m.officeBn ?? ''}');
      return words.every(hay.contains);
    }).toList()
      ..sort((a, b) => (a.seatNo ?? 9999).compareTo(b.seatNo ?? 9999));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Bootstrap>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.brand));
            }
            if (snap.hasError || !snap.hasData) {
              return ErrorView(message: '${snap.error ?? 'কিছু একটা ভুল হয়েছে'}', onRetry: _refresh);
            }

            final data = snap.data!;
            final shown = _filter(data.members);

            return RefreshIndicator(
              color: AppColors.brand,
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(context, data, shown.length)),
                  if (shown.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'কাউকে পাওয়া যায়নি',
                        body: 'নাম, আসন বা জেলা দিয়ে আবার খুঁজে দেখুন।',
                        actionLabel: 'সব দেখুন',
                        onAction: () => setState(() {
                          _search.clear();
                          _query = '';
                          _party = null;
                          _district = null;
                        }),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 4, AppSizes.pagePad, 24),
                      sliver: SliverList.separated(
                        itemCount: shown.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => MemberTile(
                          member: shown[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => MemberScreen(member: shown[i])),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Bootstrap data, int shownCount) {
    final districts = data.districts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 10, AppSizes.pagePad, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('সংসদ সদস্য', style: Theme.of(context).textTheme.displaySmall),
                    Text(
                      '${bn(data.parliamentNo)}তম জাতীয় সংসদ, ${bn(data.members.length)} জন',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'স্বাধীন, বেসরকারি তথ্যসেবা; সরকারি অ্যাপ নয়',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 14, AppSizes.pagePad, 12),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'নাম, আসন বা জেলা দিয়ে খুঁজুন',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    ),
            ),
          ),
        ),
        ChipBar(
          options: [
            (label: 'সব দল', value: null),
            ...data.parties.map((p) => (label: '${p.shortBn} (${bn(p.seats)})', value: p.abbr)),
          ],
          selected: _party,
          onSelect: (v) => setState(() => _party = v == _party ? null : v),
        ),
        const SizedBox(height: 8),
        ChipBar(
          options: [
            (label: 'সব জেলা', value: null),
            ...districts.map((d) => (label: d, value: d)),
          ],
          selected: _district,
          onSelect: (v) => setState(() => _district = v == _district ? null : v),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 12, AppSizes.pagePad, 8),
          child: Row(
            children: [
              Text('${bn(shownCount)} জন', style: Theme.of(context).textTheme.bodySmall),
              const Spacer(),
              if (_party != null || _district != null || _query.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _search.clear();
                    _query = '';
                    _party = null;
                    _district = null;
                  }),
                  child: const Text(
                    'ফিল্টার সরান',
                    style: TextStyle(fontFamily: 'NotoSansBengali', fontWeight: FontWeight.w600, color: AppColors.brand),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
