import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../brand_header.dart';
import '../bn.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'adviser_screen.dart';
import 'member_screen.dart';

/// The cabinet, in the order the secretariat lists it: the Prime Minister, then
/// ministers, ministers of state, deputy ministers and advisers. An adviser who
/// is not a member of parliament is shown too, and plainly marked as one.
class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  late Future<List<CabinetPost>> _future = Api.instance.cabinet();

  void _reload() => setState(() => _future = Api.instance.cabinet());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const BrandHeader(
            title: 'মন্ত্রিসভা',
            subtitle: 'প্রধানমন্ত্রী, মন্ত্রী, প্রতিমন্ত্রী ও উপদেষ্টা',
          ),
          Expanded(
            child: FutureBuilder<List<CabinetPost>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
                  );
                }
                if (snap.hasError) {
                  return ErrorView(message: '${snap.error}', onRetry: _reload);
                }
                final posts = snap.data ?? const <CabinetPost>[];
                if (posts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.account_balance_outlined,
                    title: 'মন্ত্রিসভার তালিকা পাওয়া যায়নি',
                    body: 'তালিকা প্রকাশিত হলে এখানে দেখা যাবে।',
                  );
                }

                // Grouped by office in order of precedence. The list's own order is
                // only the order within each source list, and put the advisers
                // above the Prime Minister.
                const rank = [
                  'প্রধানমন্ত্রী',
                  'মন্ত্রী',
                  'প্রতিমন্ত্রী',
                  'উপমন্ত্রী',
                  'উপদেষ্টা',
                ];
                int rankOf(String title) {
                  final i = rank.indexOf(title);
                  return i < 0 ? rank.length : i;
                }

                // One card per person: the list has a row per ministry, and a
                // minister with three portfolios is one minister, not three.
                final groups =
                    <
                      String,
                      List<({CabinetPost post, List<String> ministries})>
                    >{};
                final seen =
                    <String, ({CabinetPost post, List<String> ministries})>{};
                for (final p in [
                  ...posts,
                ]..sort((a, b) => rankOf(a.title).compareTo(rankOf(b.title)))) {
                  final who = '${p.title}|${p.member?.id ?? p.plainHolder}';
                  final held = seen[who];
                  if (held != null) {
                    if (p.ministryBn != null &&
                        !held.ministries.contains(p.ministryBn)) {
                      held.ministries.add(p.ministryBn!);
                    }
                    continue;
                  }
                  final entry = (
                    post: p,
                    ministries: [if (p.ministryBn != null) p.ministryBn!],
                  );
                  seen[who] = entry;
                  groups.putIfAbsent(p.title, () => []).add(entry);
                }
                final peopleCount = {
                  for (final e in seen.values)
                    e.post.member?.id ?? e.post.plainHolder,
                }.length;

                return RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: () async => _reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePad,
                      16,
                      AppSizes.pagePad,
                      28,
                    ),
                    children: [
                      Text(
                        'মোট ${bn(peopleCount)} জন দায়িত্বে',
                        style: const TextStyle(
                          fontFamily: 'NotoSansBengali',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final entry in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, top: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.brand,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandSoft,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusPill,
                                  ),
                                ),
                                child: Text(
                                  bn(entry.value.length),
                                  style: const TextStyle(
                                    fontFamily: 'NotoSansBengali',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final e in entry.value) ...[
                          _PostCard(post: e.post, ministries: e.ministries),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CabinetPost post;
  final List<String> ministries;
  const _PostCard({required this.post, this.ministries = const []});

  @override
  Widget build(BuildContext context) {
    final m = post.member;
    final adviser = post.adviserSlug;
    final body = Row(
      children: [
        if (m != null)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.party(m.party).withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: MemberAvatar(member: m, size: 50),
          )
        else
          // An adviser has no member record, but the cabinet list carries a photograph.
          ClipOval(
            child: SizedBox(
              width: 52,
              height: 52,
              child: post.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: post.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          Container(color: AppColors.sunk),
                    )
                  : Container(
                      color: AppColors.sunk,
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.muted,
                      ),
                    ),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m?.nameBn ?? post.plainHolder,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'NotoSansBengali',
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              if (ministries.isEmpty)
                Text(
                  m?.seatLabel ?? 'সংসদ সদস্য নন',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                for (final ministry in ministries.take(4))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7, right: 6),
                          child: Icon(
                            Icons.circle,
                            size: 5,
                            color: AppColors.brand,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ministry,
                            style: const TextStyle(
                              fontFamily: 'NotoSansBengali',
                              fontSize: 13,
                              color: AppColors.inkSoft,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              if (m == null) ...[
                const SizedBox(height: 6),
                const Pill('সংসদ সদস্য নন', colour: AppColors.muted),
              ],
            ],
          ),
        ),
        if (m != null || adviser != null)
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.rule,
            size: 24,
          ),
      ],
    );

    final VoidCallback? onTap = m != null
        ? () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => MemberScreen(member: m)))
        : adviser != null
        ? () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdviserScreen(
                slug: adviser,
                nameBn: post.plainHolder,
                photoUrl: post.photoUrl,
              ),
            ),
          )
        : null;

    return Container(
      decoration: AppDecor.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: Padding(padding: const EdgeInsets.all(12), child: body),
        ),
      ),
    );
  }
}
