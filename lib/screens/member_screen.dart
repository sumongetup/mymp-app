import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../bio.dart';
import '../bn.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'story_list.dart';

/// One member: who they are, what they hold, and what the press has written
/// about them. Opens with the name and photograph already on screen — they
/// came with the list — so the fetch never shows a blank page.
class MemberScreen extends StatefulWidget {
  final MemberBrief member;
  const MemberScreen({super.key, required this.member});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  late Future<MemberDetail> _detail;
  late Future<List<Story>> _feed;

  // The name appears in the bar only once the hero has scrolled out of sight.
  // Reading the scroll position is the one way that is certain: a height-based
  // guess inside the flexible space drew the name across the hero and the tabs
  // at the same time.
  static const _heroHeight = 300.0;
  final _scroll = ScrollController();
  bool _barTitle = false;

  @override
  void initState() {
    super.initState();
    _detail = Api.instance.member(widget.member.slug);
    _feed = Api.instance.memberFeed(widget.member.slug);
    _scroll.addListener(() {
      final show = _scroll.hasClients && _scroll.offset > _heroHeight - kToolbarHeight - 40;
      if (show != _barTitle) setState(() => _barTitle = show);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          controller: _scroll,
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: _heroHeight,
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              systemOverlayStyle: null,
              actions: [
                IconButton(
                  tooltip: 'শেয়ার',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: '${m.nameBn}, ${m.seatLabel}\n${Api.base}/mp/${m.slug}',
                      subject: m.nameBn,
                    ),
                  ),
                ),
              ],
              title: AnimatedOpacity(
                opacity: _barTitle ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  m.nameBn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSansBengali',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // The photo and name fade out as the bar collapses, and are gone
              // before they reach the tabs: sliding under them, the photo covered
              // "পরিচিতি" and "সংবাদ ও ভিডিও" halfway through a scroll.
              flexibleSpace: LayoutBuilder(
                builder: (context, box) {
                  final top = MediaQuery.paddingOf(context).top;
                  final collapsed = kToolbarHeight + kTextTabBarHeight + top;
                  final open = _heroHeight + top;
                  final t = ((box.maxHeight - collapsed) / (open - collapsed)).clamp(0.0, 1.0);
                  return FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Opacity(
                      opacity: ((t - 0.45) / 0.55).clamp(0.0, 1.0),
                      child: _hero(context, m),
                    ),
                  );
                },
              ),
              // The tabs sit on the green bar at both sizes, so they are drawn
              // in white: the brand green on brand green could not be read.
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.72),
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 14.5, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 14.5, fontWeight: FontWeight.w500),
                tabs: const [Tab(text: 'পরিচিতি'), Tab(text: 'সংবাদ ও ভিডিও')],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _profileTab(),
              StoryList(
                future: _feed,
                emptyTitle: 'এখনো কোনো সংবাদ যুক্ত হয়নি',
                emptyBody: 'সংবাদমাধ্যমে ${m.nameBn}-এর নাম এলে তা এখানে দেখানো হবে।',
                onRetry: () => setState(() => _feed = Api.instance.memberFeed(m.slug)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, MemberBrief m) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3),
                ),
                child: MemberAvatar(member: m, size: 104),
              ),
              const SizedBox(height: 12),
              if (m.officeBn != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Text(
                    m.officeBn!,
                    style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  m.nameBn,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSansBengali',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                m.seatLabel,
                style: TextStyle(
                  fontFamily: 'NotoSansBengali',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              // Clear of the tab bar drawn across the foot of the same bar.
              const SizedBox(height: kTextTabBarHeight + 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileTab() {
    return FutureBuilder<MemberDetail>(
      future: _detail,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.brand));
        }
        if (snap.hasError || !snap.hasData) {
          return ErrorView(
            message: '${snap.error ?? 'তথ্য পাওয়া যায়নি'}',
            onRetry: () => setState(() => _detail = Api.instance.member(widget.member.slug)),
          );
        }
        final d = snap.data!;
        final facts = <({String label, String value})>[
          if (d.partyNameBn != null) (label: 'দল', value: d.partyNameBn!),
          if (d.partyRoleBn != null) (label: 'দলীয় পদ', value: d.partyRoleBn!),
          if (d.ministryBn != null) (label: 'মন্ত্রণালয়', value: d.ministryBn!),
          if (d.brief.districtBn != null) (label: 'জেলা', value: d.brief.districtBn!),
          if (d.professionBn != null) (label: 'পেশা', value: d.professionBn!),
          if (d.educationBn != null) (label: 'শিক্ষা', value: d.educationBn!),
          if (d.birthPlaceBn != null) (label: 'জন্মস্থান', value: d.birthPlaceBn!),
          if (dateBn(d.dateOfBirth) != null) (label: 'জন্ম', value: dateBn(d.dateOfBirth)!),
          if (d.fatherBn != null) (label: 'পিতা', value: d.fatherBn!),
          if (d.motherBn != null) (label: 'মাতা', value: d.motherBn!),
          if (d.termsCount != null) (label: 'নির্বাচিত', value: '${bn(d.termsCount!)} বার'),
          if (d.isFreedomFighter) (label: 'মুক্তিযোদ্ধা', value: 'হ্যাঁ'),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 16, AppSizes.pagePad, 32),
          children: [
            // The written biography, with its sources; the presiding officers'
            // one-paragraph summary from parliament when there is no biography.
            if (d.bioBn != null)
              BioCard(text: d.bioBn!, sources: d.bioSources)
            else if (d.summaryBn != null)
              BioCard(text: d.summaryBn!, title: 'সংক্ষিপ্ত পরিচিতি'),
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 12),
              FactsCard(title: 'তথ্য', facts: facts),
            ],
            if (d.committees.isNotEmpty) ...[
              const SizedBox(height: 12),
              _card(
                context,
                'সংসদীয় কমিটি',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in d.committees)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4, right: 8),
                              child: Icon(Icons.circle, size: 7, color: AppColors.brandRing),
                            ),
                            Expanded(child: Text(c.nameBn, style: Theme.of(context).textTheme.bodyLarge)),
                            if (c.role != null) Pill(c.role!),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (d.priorTerms.isNotEmpty) ...[
              const SizedBox(height: 12),
              _card(
                context,
                'আগের মেয়াদ',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in d.priorTerms)
                      Pill('${bn(t.parliamentNo)}ম সংসদ${t.seatBn != null ? ', ${t.seatBn}' : ''}'),
                  ],
                ),
              ),
            ],
            if (d.socials.isNotEmpty || d.email != null) ...[
              const SizedBox(height: 12),
              _card(
                context,
                'যোগাযোগ ও লিংক',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (d.email != null)
                      _linkRow(context, Icons.mail_outline_rounded, d.email!, () => _open('mailto:${d.email}')),
                    for (final s in d.socials)
                      _linkRow(context, Icons.open_in_new_rounded, s.label, () => _open(s.url)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => _open('${Api.base}/mp/${d.brief.slug}'),
                icon: const Icon(Icons.public_rounded, size: 18, color: AppColors.brand),
                label: const Text(
                  'ওয়েবসাইটে দেখুন',
                  style: TextStyle(fontFamily: 'NotoSansBengali', fontWeight: FontWeight.w600, color: AppColors.brand),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'সূত্র: বাংলাদেশ জাতীয় সংসদ',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, String title, Widget body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  Widget _linkRow(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.brand),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyLarge),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
