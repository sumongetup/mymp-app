import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../bn.dart';
import '../models.dart';
import '../theme.dart';

import 'party_screen.dart';

/// The parties, and the handful of things a reader looks for once: where the
/// figures come from, what the app stores, how to report a mistake.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final data = Api.instance.cached;
    final parties = data?.parties ?? const <PartyBrief>[];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 10, AppSizes.pagePad, 32),
          children: [
            Text('আরও', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 18),

            if (parties.isNotEmpty) ...[
              Text('দল', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              for (final p in parties) ...[
                _PartyRow(party: p),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 18),
            ],

            Text('সম্পর্কে', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                border: Border.all(color: AppColors.rule),
              ),
              child: Column(
                children: [
                  _row(context, Icons.info_outline_rounded, 'আমার এমপি সম্পর্কে', () => _open('${Api.base}/somporke')),
                  const Divider(height: 1),
                  _row(context, Icons.verified_outlined, 'তথ্যের সূত্র', () => _open('${Api.base}/sutro')),
                  const Divider(height: 1),
                  _row(context, Icons.lock_outline_rounded, 'গোপনীয়তা নীতি', () => _open('${Api.base}/gopaniyota')),
                  const Divider(height: 1),
                  _row(context, Icons.mail_outline_rounded, 'ভুল জানান / যোগাযোগ', () => _open('${Api.base}/jogajog')),
                  const Divider(height: 1),
                  _row(context, Icons.public_rounded, 'ওয়েবসাইট: mymp.bd', () => _open(Api.base)),
                  const Divider(height: 1),
                  _row(
                    context,
                    Icons.share_outlined,
                    'অ্যাপটি শেয়ার করুন',
                    () => SharePlus.instance.share(
                      ShareParams(text: 'আমার এমপি — বাংলাদেশের সংসদ সদস্যদের তথ্য: ${Api.base}'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('এই অ্যাপ কী রাখে', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'কোনো অ্যাকাউন্ট লাগে না, কিছু জমা নেওয়া হয় না। শুধু সংসদ সদস্যদের তালিকাটি ফোনেই রেখে দেওয়া হয়, '
                    'যাতে নেটওয়ার্ক না থাকলেও অ্যাপ খোলে। সব তথ্য mymp.bd থেকে আসে।',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                data == null ? 'সংস্করণ ১.০.০' : 'সংস্করণ ১.০.০ · ${bn(data.parliamentNo)}তম সংসদ',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.brand),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  final PartyBrief party;
  const _PartyRow({required this.party});

  @override
  Widget build(BuildContext context) {
    final colour = AppColors.party(party.abbr);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PartyScreen(party: party))),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(color: AppColors.rule),
          ),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: colour, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(party.shortBn, style: Theme.of(context).textTheme.titleMedium),
                    if (party.nameBn != party.shortBn)
                      Text(party.nameBn, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Text('${bn(party.seats)} আসন', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
