import 'package:flutter/material.dart';

import '../api.dart';
import '../bn.dart';
import '../brand_header.dart';
import '../models.dart';
import '../party_logo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'leaders_strip.dart';
import 'member_screen.dart';

/// The list every reader opens first: all 348 members, searchable by name, by
/// seat and by district, filterable by party and district.
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
    // The list opens from the copy on the phone; when the fresh one arrives in
    // the background, it replaces what is on screen without a pull.
    Api.instance.onBootstrapUpdated = (fresh) {
      if (mounted) setState(() => _future = Future.value(fresh));
    };
  }

  @override
  void dispose() {
    Api.instance.onBootstrapUpdated = null;
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final fresh = Api.instance.loadBootstrap(force: true);
    setState(() => _future = fresh);
    await fresh;
  }

  void _clearAll() => setState(() {
    _search.clear();
    _query = '';
    _party = null;
    _district = null;
  });

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
    final words = _fold(
      _query,
    ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return all.where((m) {
      if (_party != null && m.party != _party) return false;
      if (_district != null && m.districtBn != _district) return false;
      if (words.isEmpty) return true;
      final hay = _fold(
        '${m.nameBn} ${m.nameEn ?? ''} ${m.seatBn ?? ''} ${m.districtBn ?? ''} ${m.officeBn ?? ''}',
      );
      return words.every(hay.contains);
    }).toList()..sort((a, b) => (a.seatNo ?? 9999).compareTo(b.seatNo ?? 9999));
  }

  Future<void> _pickDistrict(List<String> districts) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DistrictSheet(districts: districts, selected: _district),
    );
    if (picked == null) return;
    setState(() => _district = picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Bootstrap>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return SafeArea(
              child: ErrorView(
                message: '${snap.error ?? 'কিছু একটা ভুল হয়েছে'}',
                onRetry: _refresh,
              ),
            );
          }

          final data = snap.data!;
          final shown = _filter(data.members);
          final filtered =
              _party != null || _district != null || _query.isNotEmpty;

          return RefreshIndicator(
            color: AppColors.brand,
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header(data)),
                // The House's leaders and the election figures first; a reader
                // searching or filtering wants the list, so they step aside.
                if (!filtered) ...[
                  SliverToBoxAdapter(child: LeadersStrip(data: data)),
                  const SliverToBoxAdapter(child: ElectionCard()),
                ],
                SliverToBoxAdapter(
                  child: _filters(data, shown.length, filtered),
                ),
                if (shown.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'কাউকে পাওয়া যায়নি',
                      body: 'নাম, আসন বা জেলা দিয়ে আবার খুঁজে দেখুন।',
                      actionLabel: 'সব দেখুন',
                      onAction: _clearAll,
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePad,
                      2,
                      AppSizes.pagePad,
                      0,
                    ),
                    sliver: SliverList.separated(
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => MemberTile(
                        member: shown[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MemberScreen(member: shown[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _Footnote()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(Bootstrap data) {
    return BrandHeader(
      title: 'সংসদ সদস্য',
      subtitle: '${parliamentBn(data.parliamentNo)} জাতীয় সংসদ',
      bottom: Column(
        children: [
          Row(
            children: [
              HeaderStat(value: bn(data.members.length), label: 'সদস্য'),
              const SizedBox(width: 8),
              HeaderStat(value: bn(data.parties.length), label: 'দল'),
              const SizedBox(width: 8),
              HeaderStat(value: bn(data.districts.length), label: 'জেলা'),
            ],
          ),
          const SizedBox(height: 14),
          HeaderSearchField(
            controller: _search,
            hint: 'নাম, আসন বা জেলা দিয়ে খুঁজুন',
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() {
              _search.clear();
              _query = '';
            }),
          ),
        ],
      ),
    );
  }

  Widget _filters(Bootstrap data, int shownCount, bool filtered) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipBar(
            options: [
              (label: 'সব দল', value: null),
              ...data.parties.map(
                (p) => (label: '${p.shortBn} ${bn(p.seats)}', value: p.abbr),
              ),
            ],
            selected: _party,
            leading: (v) => v == null ? null : PartyLogo(abbr: v, size: 18),
            onSelect: (v) => setState(() => _party = v == _party ? null : v),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePad),
            child: Row(
              children: [
                _DistrictButton(
                  label: _district ?? 'সব জেলা',
                  active: _district != null,
                  onTap: () => _pickDistrict(data.districts),
                  onClear: _district == null
                      ? null
                      : () => setState(() => _district = null),
                ),
                const Spacer(),
                Text(
                  '${bn(shownCount)} জন',
                  style: const TextStyle(
                    fontFamily: 'NotoSansBengali',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                if (filtered) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text(
                      'সব মুছুন',
                      style: TextStyle(
                        fontFamily: 'NotoSansBengali',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistrictButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DistrictButton({
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.brandSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        child: Container(
          height: 36,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(
              color: active ? AppColors.brandRing : AppColors.rule,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 17,
                color: active ? AppColors.brand : AppColors.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoSansBengali',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.brand : AppColors.inkSoft,
                ),
              ),
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.brand,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 64 districts in a sheet, with a search box: a row of 64 chips was a
/// long sideways scroll to reach Sylhet.
class _DistrictSheet extends StatefulWidget {
  final List<String> districts;
  final String? selected;
  const _DistrictSheet({required this.districts, this.selected});

  @override
  State<_DistrictSheet> createState() => _DistrictSheetState();
}

class _DistrictSheetState extends State<_DistrictSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.districts
        .where((d) => _q.isEmpty || d.contains(_q))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.rule,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePad,
                  14,
                  AppSizes.pagePad,
                  10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'জেলা বেছে নিন',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (widget.selected != null)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(''),
                        child: const Text(
                          'সব জেলা',
                          style: TextStyle(
                            fontFamily: 'NotoSansBengali',
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePad,
                ),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _q = v.trim()),
                  decoration: const InputDecoration(
                    hintText: 'জেলার নাম',
                    isDense: true,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final d = list[i];
                    final on = d == widget.selected;
                    return ListTile(
                      dense: true,
                      title: Text(
                        d,
                        style: TextStyle(
                          fontFamily: 'NotoSansBengali',
                          fontSize: 15,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                          color: on ? AppColors.brand : AppColors.ink,
                        ),
                      ),
                      trailing: on
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.brand,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(d),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the list comes from, and that this is not the government's app.
class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePad,
        18,
        AppSizes.pagePad,
        28,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'আমার এমপি একটি স্বাধীন, বেসরকারি তথ্যসেবা; সরকারি অ্যাপ নয়। সদস্যদের তথ্য জাতীয় সংসদের ওয়েবসাইট থেকে নেওয়া।',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
