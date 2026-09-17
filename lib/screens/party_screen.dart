import 'package:flutter/material.dart';

import '../api.dart';
import '../bn.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'member_screen.dart';

/// Everyone elected for one party, in seat order. Read from the list already on
/// the phone, so it opens with no wait and works with no signal.
class PartyScreen extends StatelessWidget {
  final PartyBrief party;
  const PartyScreen({super.key, required this.party});

  @override
  Widget build(BuildContext context) {
    final members =
        (Api.instance.cached?.members ?? const <MemberBrief>[])
            .where((m) => m.party == party.abbr)
            .toList()
          ..sort((a, b) => (a.seatNo ?? 9999).compareTo(b.seatNo ?? 9999));
    final colour = AppColors.party(party.abbr);

    return Scaffold(
      appBar: AppBar(title: Text(party.nameBn)),
      body: members.isEmpty
          ? const EmptyState(
              icon: Icons.group_outlined,
              title: 'কোনো সদস্য নেই',
              body: 'এই দলের কোনো নির্বাচিত সদস্য তালিকায় নেই।',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePad,
                12,
                AppSizes.pagePad,
                28,
              ),
              itemCount: members.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colour.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                      border: Border.all(color: colour.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: colour,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${bn(members.length)} জন সংসদ সদস্য',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final m = members[i - 1];
                return MemberTile(
                  member: m,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MemberScreen(member: m)),
                  ),
                );
              },
            ),
    );
  }
}
