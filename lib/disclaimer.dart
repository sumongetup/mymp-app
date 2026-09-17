import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loading.dart';
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
  (
    label: 'বাংলাদেশ জাতীয় সংসদ: parliament.gov.bd',
    url: 'https://www.parliament.gov.bd',
  ),
  (label: 'বাংলাদেশ নির্বাচন কমিশন: ecs.gov.bd', url: 'https://www.ecs.gov.bd'),
  (label: 'মন্ত্রিপরিষদ বিভাগ: cabinet.gov.bd', url: 'https://cabinet.gov.bd'),
];

/// The statement with the official sources as links, for the "আরও" tab.
class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.card(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            color: AppColors.warnSoft,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 19,
                    color: AppColors.warn,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'স্বাধীন, বেসরকারি তথ্যসেবা। সংসদ, নির্বাচন কমিশন বা সরকারের কোনো দপ্তরের অ্যাপ নয়।',
                    style: TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 2),
            child: Text(
              'তথ্যের সরকারি সূত্র',
              style: TextStyle(
                fontFamily: 'NotoSansBengali',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          for (final s in kOfficialSources)
            InkWell(
              onTap: () => openLink(context, s.url),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_outlined,
                      size: 17,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.label,
                        style: const TextStyle(
                          fontFamily: 'NotoSansBengali',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
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
      title: const Text(
        'আমার এমপি সম্পর্কে',
        style: TextStyle(
          fontFamily: 'NotoSansBengali',
          fontWeight: FontWeight.w700,
        ),
      ),
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
          child: const Text(
            'বুঝেছি',
            style: TextStyle(
              fontFamily: 'NotoSansBengali',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  await prefs.setBool(key, true);
}
