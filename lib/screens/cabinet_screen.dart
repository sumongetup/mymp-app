import 'package:flutter/material.dart';

import '../api.dart';
import '../bn.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
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
      body: SafeArea(
        child: FutureBuilder<List<CabinetPost>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.brand));
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
            const rank = ['প্রধানমন্ত্রী', 'মন্ত্রী', 'প্রতিমন্ত্রী', 'উপমন্ত্রী', 'উপদেষ্টা'];
            int rankOf(String title) {
              final i = rank.indexOf(title);
              return i < 0 ? rank.length : i;
            }
            final groups = <String, List<CabinetPost>>{};
            for (final p in [...posts]..sort((a, b) => rankOf(a.title).compareTo(rankOf(b.title)))) {
              groups.putIfAbsent(p.title, () => []).add(p);
            }

            return RefreshIndicator(
              color: AppColors.brand,
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 10, AppSizes.pagePad, 28),
                children: [
                  Text('মন্ত্রিসভা', style: Theme.of(context).textTheme.displaySmall),
                  Text(
                    '${bn(posts.length)} জন দায়িত্বে',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 6),
                      child: Row(
                        children: [
                          Text(entry.key, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(width: 8),
                          Text('${bn(entry.value.length)} জন', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    for (final post in entry.value) ...[
                      _PostCard(post: post),
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
    );
  }
}

class _PostCard extends StatelessWidget {
  final CabinetPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final m = post.member;
    final body = Row(
      children: [
        if (m != null)
          MemberAvatar(member: m)
        else
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: AppColors.sunk, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.muted),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m?.nameBn ?? post.holderBn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                post.ministryBn ?? (m?.seatLabel ?? 'সংসদ সদস্য নন'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (m == null) ...[
                const SizedBox(height: 6),
                const Pill('সংসদ সদস্য নন', colour: AppColors.muted),
              ],
            ],
          ),
        ),
        if (m != null) const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 22),
      ],
    );

    if (m == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(color: AppColors.rule),
        ),
        child: body,
      );
    }

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MemberScreen(member: m))),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(color: AppColors.rule),
          ),
          child: body,
        ),
      ),
    );
  }
}
