import 'package:flutter/material.dart';

import '../api.dart';
import '../bn.dart';
import '../loading.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'member_screen.dart';

int _n(dynamic v) => v is num ? v.toInt() : 0;
List<Map<String, dynamic>> _list(dynamic v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

/// A string field, or null when the server sent anything else: one odd value
/// must not turn the whole screen into an error.
String? _str(dynamic v) => v is String ? v : null;
Map<String, dynamic> _map(dynamic v) =>
    v is Map<String, dynamic> ? v : const {};

/// ত্রয়োদশ জাতীয় সংসদ নির্বাচন in figures: the House by party, the voters,
/// the votes, the closest and widest wins, and who the members are.
class ElectionScreen extends StatefulWidget {
  const ElectionScreen({super.key});

  @override
  State<ElectionScreen> createState() => _ElectionScreenState();
}

class _ElectionScreenState extends State<ElectionScreen> {
  late Future<Map<String, dynamic>> _future = Api.instance.election();

  Future<void> _refresh() async {
    final f = Api.instance.election(force: true);
    setState(() {
      _future = f;
    });
    await settle(f);
  }

  void _openMember(MemberBrief m) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => MemberScreen(member: m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নির্বাচন পরিসংখ্যান')),
      body: Loaded<Map<String, dynamic>>(
        future: _future,
        onRetry: () => setState(() {
          _future = Api.instance.election();
        }),
        builder: (context, e) => RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refresh,
          child: _body(e),
        ),
      ),
    );
  }

  Widget _body(Map<String, dynamic> e) {
    final dates = _map(e['dates']);
    final house = _map(e['house']);
    final voters = _map(e['voters']);
    final results = _map(e['results']);
    final people = _map(e['members']);
    final text = Theme.of(context).textTheme;

    final total = _n(house['total']);
    final majority = _n(house['majority']);
    final parties = _list(house['parties']);
    final totalVotes = _n(results['totalVotes']);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSizes.pagePad,
        14,
        AppSizes.pagePad,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _Hero(
          parliamentNo: _n(e['parliamentNo']),
          electionDate: _str(dates['election']),
          total: total,
          seatsCounted: _n(results['seatsCounted']),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'গুরুত্বপূর্ণ তারিখ',
          child: _Grid(
            items: [
              for (final (label, key) in const [
                ('ভোটগ্রহণ', 'election'),
                ('গেজেট', 'gazette'),
                ('শপথ', 'oath'),
                ('মেয়াদ শেষ', 'end'),
              ])
                (value: dateBn(_str(dates[key])) ?? 'তারিখ নেই', label: label),
            ],
            valueSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'সংসদের গঠন',
          subtitle:
              'সংরক্ষিত আসনসহ ${bn(total)} জন। কালো দাগ সংখ্যাগরিষ্ঠতার ${bn(majority)} আসন।',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StackBar(
                parts: [
                  for (final p in parties)
                    (
                      color: AppColors.party(_str(p['abbr'])),
                      value: _n(p['seats']),
                    ),
                ],
                total: total,
                marker: total > 0 ? majority / total : null,
              ),
              const SizedBox(height: 14),
              for (final p in parties)
                _PartyRow(
                  abbr: _str(p['abbr']),
                  label: _str(p['labelBn']) ?? '',
                  value: '${bn(_n(p['seats']))} আসন',
                  note: 'সাধারণ আসনে ${bn(_n(p['seatsTerritorial']))}',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'ভোটার ও ভোটকেন্দ্র',
          subtitle: 'সারা দেশের হিসাব',
          footer:
              'সূত্র: ${voters['sourceBn'] ?? 'নির্বাচন কমিশন'}${dateBn(_str(voters['readOn'])) != null ? ', পড়া হয়েছে ${dateBn(_str(voters['readOn']))}' : ''}',
          child: Column(
            children: [
              _Grid(
                items: [
                  (
                    value: bnGroup(_n(voters['registered'])),
                    label: 'মোট ভোটার',
                  ),
                  (
                    value: bnGroup(_n(voters['pollingCentres'])),
                    label: 'ভোটকেন্দ্র',
                  ),
                  (value: bnGroup(_n(voters['male'])), label: 'পুরুষ ভোটার'),
                  (value: bnGroup(_n(voters['female'])), label: 'নারী ভোটার'),
                ],
              ),
              const SizedBox(height: 12),
              _StackBar(
                parts: [
                  (color: const Color(0xFF7FA99A), value: _n(voters['male'])),
                  (color: AppColors.brand, value: _n(voters['female'])),
                ],
                total: _n(voters['registered']),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'পুরুষ ${pctBn(_n(voters['male']), _n(voters['registered']))}',
                    style: text.labelSmall,
                  ),
                  const Spacer(),
                  Text(
                    'নারী ${pctBn(_n(voters['female']), _n(voters['registered']))}',
                    style: text.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (totalVotes > 0) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'দলভিত্তিক ভোট',
            subtitle:
                '${bn(_n(results['seatsCounted']))}টি আসনে প্রার্থীরা মোট ${bnGroup(totalVotes)} ভোট পেয়েছেন',
            footer: _str(results['sourceBn']),
            child: Column(
              children: [
                for (final v in _list(results['voteShare']))
                  _ShareRow(
                    abbr: _str(v['abbr']),
                    label: _str(v['labelBn']) ?? '',
                    votes: _n(v['votes']),
                    total: totalVotes,
                  ),
              ],
            ),
          ),
        ],
        if (_list(results['closest']).isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'সবচেয়ে কম ব্যবধানে জয়',
            child: _MarginList(
              rows: _list(results['closest']),
              onOpen: _openMember,
            ),
          ),
        ],
        if (_list(results['widest']).isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'সবচেয়ে বড় ব্যবধানে জয়',
            child: _MarginList(
              rows: _list(results['widest']),
              onOpen: _openMember,
            ),
          ),
        ],
        const SizedBox(height: 12),
        _Section(
          title: 'নির্বাচিত সদস্যরা',
          subtitle: 'বর্তমান ${bn(total)} জন সংসদ সদস্যের তথ্য থেকে',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Grid(
                items: [
                  (value: '${bn(_n(people['women']))} জন', label: 'নারী সদস্য'),
                  (
                    value: people['medianAge'] is num
                        ? '${bn(_n(people['medianAge']))} বছর'
                        : 'তথ্য নেই',
                    label: 'বয়সের মধ্যক',
                  ),
                  (
                    value: '${bn(_n(people['firstTime']))} জন',
                    label: 'প্রথমবার সংসদে',
                  ),
                  (
                    value: '${bn(_n(people['freedomFighters']))} জন',
                    label: 'মুক্তিযোদ্ধা',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'নারী সদস্যদের ${bn(_n(people['womenTerritorial']))} জন সাধারণ আসনে নির্বাচিত, ${bn(_n(people['womenReserved']))} জন সংরক্ষিত আসনে।',
                style: text.labelSmall?.copyWith(height: 1.5),
              ),
              for (final (key, label) in const [
                ('youngest', 'সর্বকনিষ্ঠ'),
                ('oldest', 'সর্বজ্যেষ্ঠ'),
              ])
                if (people[key] is Map<String, dynamic>)
                  _PersonRow(
                    label: label,
                    member: MemberBrief.fromJson(
                      _map(_map(people[key])['member']),
                    ),
                    trailing: '${bn(_n(_map(people[key])['age']))} বছর',
                    onOpen: _openMember,
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'বয়স',
          child: _Bars(
            rows: [
              for (final b in _list(people['ageBands']))
                (label: _str(b['label']) ?? '', count: _n(b['count'])),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'সংসদে অভিজ্ঞতা',
          subtitle:
              '${bn(_n(people['firstTime']))} জন এবারই প্রথম, ${bn(_n(people['returning']))} জন আগেও সদস্য ছিলেন',
          child: _Bars(
            rows: [
              for (final b in _list(people['experience']))
                (label: _str(b['label']) ?? '', count: _n(b['count'])),
            ],
            labelWidth: 118,
          ),
        ),
        if (_list(people['professions']).isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'পেশা',
            subtitle: 'সংসদের তথ্যভান্ডারে লিপিবদ্ধ পেশা অনুযায়ী',
            child: _Bars(
              rows: [
                for (final b in _list(people['professions']))
                  (label: _str(b['label']) ?? '', count: _n(b['count'])),
              ],
              labelWidth: 118,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'সদস্যদের তথ্য জাতীয় সংসদের ওয়েবসাইট থেকে, ভোটার সংখ্যা নির্বাচন কমিশন থেকে। আমার এমপি একটি স্বাধীন, বেসরকারি তথ্যসেবা।',
          textAlign: TextAlign.center,
          style: text.labelSmall?.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final int parliamentNo;
  final String? electionDate;
  final int total;
  final int seatsCounted;
  const _Hero({
    required this.parliamentNo,
    required this.electionDate,
    required this.total,
    required this.seatsCounted,
  });

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(fontFamily: 'NotoSansBengali', color: Colors.white);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppDecor.headerGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppDecor.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.how_to_vote_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                dateBn(electionDate) ?? '২০২৬',
                style: white.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${parliamentBn(parliamentNo)} জাতীয় সংসদ নির্বাচন',
            style: white.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _heroStat('৩০০', 'সাধারণ আসন'),
              _heroStat('৫০', 'সংরক্ষিত আসন'),
              _heroStat(bn(total), 'বর্তমান সদস্য'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'NotoSansBengali',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansBengali',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? footer;
  final Widget child;
  const _Section({
    required this.title,
    this.subtitle,
    this.footer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: text.labelSmall?.copyWith(height: 1.45)),
          ],
          const SizedBox(height: 14),
          child,
          if (footer != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.ruleSoft),
            const SizedBox(height: 10),
            Text(footer!, style: text.labelSmall?.copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }
}

/// Two columns of big figures.
class _Grid extends StatelessWidget {
  final List<({String value, String label})> items;
  final double valueSize;
  const _Grid({required this.items, this.valueSize = 19});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final i in items)
              Container(
                width: w,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.value,
                      style: TextStyle(
                        fontFamily: 'NotoSansBengali',
                        fontSize: valueSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      i.label,
                      style: const TextStyle(
                        fontFamily: 'NotoSansBengali',
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One bar split by share, with an optional line at the majority mark.
class _StackBar extends StatelessWidget {
  final List<({Color color, int value})> parts;
  final int total;
  final double? marker;
  const _StackBar({required this.parts, required this.total, this.marker});

  @override
  Widget build(BuildContext context) {
    final rest = total - parts.fold<int>(0, (n, p) => n + p.value);
    return LayoutBuilder(
      builder: (context, box) => SizedBox(
        height: 30,
        child: Stack(
          children: [
            Positioned.fill(
              top: 4,
              bottom: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    for (final p in parts)
                      if (p.value > 0)
                        Expanded(
                          flex: p.value,
                          child: Container(
                            color: p.color,
                            margin: const EdgeInsets.only(right: 1),
                          ),
                        ),
                    if (rest > 0)
                      Expanded(
                        flex: rest,
                        child: Container(color: AppColors.sunk),
                      ),
                  ],
                ),
              ),
            ),
            if (marker != null)
              Positioned(
                left: (box.maxWidth * marker!).clamp(0, box.maxWidth - 2),
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: AppColors.ink),
              ),
          ],
        ),
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  final String? abbr;
  final String label;
  final String value;
  final String? note;
  const _PartyRow({
    required this.abbr,
    required this.label,
    required this.value,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PartyChip(abbr: abbr, label: label),
                if (note != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(note!, style: text.labelSmall),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'NotoSansBengali',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  final String? abbr;
  final String label;
  final int votes;
  final int total;
  const _ShareRow({
    required this.abbr,
    required this.label,
    required this.votes,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colour = AppColors.party(abbr == 'other' ? null : abbr);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PartyChip(
                  abbr: abbr == 'other' ? null : abbr,
                  label: label,
                ),
              ),
              Text(
                pctBn(votes, total),
                style: const TextStyle(
                  fontFamily: 'NotoSansBengali',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? votes / total : 0,
              minHeight: 8,
              color: colour,
              backgroundColor: AppColors.sunk,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${bnGroup(votes)} ভোট',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  final List<({String label, int count})> rows;
  final double labelWidth;
  const _Bars({required this.rows, this.labelWidth = 78});

  @override
  Widget build(BuildContext context) {
    final max = rows.fold<int>(1, (m, r) => r.count > m ? r.count : m);
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    r.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 13,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: r.count / max,
                      minHeight: 12,
                      color: AppColors.brand,
                      backgroundColor: AppColors.sunk,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    bn(r.count),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MarginList extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final void Function(MemberBrief) onOpen;
  const _MarginList({required this.rows, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in rows)
          if (r['member'] is Map<String, dynamic>)
            _PersonRow(
              label: _str(r['seatBn']) ?? '',
              member: MemberBrief.fromJson(_map(r['member'])),
              trailing: '${bnGroup(_n(r['margin']))} ভোটে',
              note: r['runnerUpParty'] != null
                  ? 'নিকটতম: ${r['runnerUpParty']}'
                  : null,
              onOpen: onOpen,
            ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  final String label;
  final MemberBrief member;
  final String trailing;
  final String? note;
  final void Function(MemberBrief) onOpen;
  const _PersonRow({
    required this.label,
    required this.member,
    required this.trailing,
    this.note,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => onOpen(member),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            MemberAvatar(member: member, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: text.labelSmall),
                  Text(
                    member.nameBn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (note != null) Text(note!, style: text.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              trailing,
              style: const TextStyle(
                fontFamily: 'NotoSansBengali',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
