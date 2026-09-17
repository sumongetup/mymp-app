import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

/// Google Play asks an app that shows government information to say, in the
/// app and in its listing, that it does not represent the government, and to
/// name where the information comes from. This file is that statement, in one
/// place, and the official sources it points to.

const kNotOfficial =
    'আমার এমপি একটি স্বাধীন, বেসরকারি তথ্যসেবা। এটি বাংলাদেশ জাতীয় সংসদ, নির্বাচন কমিশন, মন্ত্রিপরিষদ বিভাগ '
    'বা সরকারের কোনো দপ্তরের অ্যাপ নয়, কোনো সরকারি প্রতিষ্ঠানের সঙ্গে যুক্তও নয়।';

const kSourcesLine =
    'সংসদ সদস্যদের তথ্য নেওয়া হয় জাতীয় সংসদের ওয়েবসাইট থেকে, নির্বাচনী ফল প্রকাশিত ফলাফল থেকে, আর মন্ত্রিসভার তালিকা '
    'মন্ত্রিপরিষদ বিভাগের ওয়েবসাইট থেকে। প্রতিটি সদস্যের পাতায় তথ্যের সূত্র দেওয়া আছে।';

/// The official sites the information comes from, as the reader can check them.
const kOfficialSources = <({String label, String url})>[
  (label: 'বাংলাদেশ জাতীয় সংসদ: parliament.gov.bd', url: 'https://www.parliament.gov.bd'),
  (label: 'বাংলাদেশ নির্বাচন কমিশন: ecs.gov.bd', url: 'https://www.ecs.gov.bd'),
  (label: 'মন্ত্রিপরিষদ বিভাগ: cabinet.gov.bd', url: 'https://cabinet.gov.bd'),
];

Future<void> _open(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// The statement with the official sources as links, for the "আরও" tab.
class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warnSoft,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: const Color(0xFFEAD9A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.warn),
              const SizedBox(width: 8),
              Expanded(child: Text('সরকারি অ্যাপ নয়', style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          Text(kNotOfficial, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(kSourcesLine, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text('সরকারি সূত্র', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final s in kOfficialSources)
            InkWell(
              onTap: () => _open(s.url),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.brand, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown once, the first time the app opens, before anything else is read.
Future<void> showDisclaimerOnce(BuildContext context) async {
  const key = 'not_official_notice_v1';
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(key) == true || !context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('আমার এমপি সম্পর্কে', style: TextStyle(fontFamily: 'NotoSansBengali', fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kNotOfficial, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(kSourcesLine, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('বুঝেছি', style: TextStyle(fontFamily: 'NotoSansBengali', fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  await prefs.setBool(key, true);
}
