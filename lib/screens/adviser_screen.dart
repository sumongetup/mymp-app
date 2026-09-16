import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../api.dart';
import '../bio.dart';
import '../bn.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// An adviser to the Prime Minister appointed from outside parliament: who they
/// are, what they are responsible for, and where that account comes from.
class AdviserScreen extends StatefulWidget {
  final String slug;
  final String nameBn;
  final String? photoUrl;
  const AdviserScreen({super.key, required this.slug, required this.nameBn, this.photoUrl});

  @override
  State<AdviserScreen> createState() => _AdviserScreenState();
}

class _AdviserScreenState extends State<AdviserScreen> {
  late Future<AdviserDetail> _future = Api.instance.adviser(widget.slug);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রধানমন্ত্রীর উপদেষ্টা'),
        actions: [
          IconButton(
            tooltip: 'শেয়ার',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: '${widget.nameBn}\n${Api.base}/upodeshta/${widget.slug}', subject: widget.nameBn),
            ),
          ),
        ],
      ),
      body: FutureBuilder<AdviserDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brand));
          }
          if (snap.hasError || !snap.hasData) {
            return ErrorView(
              message: '${snap.error ?? 'তথ্য পাওয়া যায়নি'}',
              onRetry: () => setState(() => _future = Api.instance.adviser(widget.slug)),
            );
          }
          final a = snap.data!;
          final facts = <({String label, String value})>[
            if (a.rankBn != null) (label: 'পদমর্যাদা', value: a.rankBn!),
            if (a.partyRoleBn != null) (label: 'দলীয় পদ', value: a.partyRoleBn!),
            if (a.professionBn != null) (label: 'পেশা', value: a.professionBn!),
            if (a.educationBn != null) (label: 'শিক্ষা', value: a.educationBn!),
            if (a.birthPlaceBn != null) (label: 'জন্মস্থান', value: a.birthPlaceBn!),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 8, AppSizes.pagePad, 32),
            children: [
              _header(context, a),
              const SizedBox(height: 16),
              if (a.posts.isNotEmpty) ...[
                _posts(context, a.posts),
                const SizedBox(height: 12),
              ],
              BioCard(text: a.bioBn, sources: a.sources),
              if (facts.isNotEmpty) ...[
                const SizedBox(height: 12),
                FactsCard(title: 'তথ্য', facts: facts),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, AdviserDetail a) {
    final photo = a.photoUrl ?? widget.photoUrl;
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 84,
            height: 84,
            child: photo == null
                ? Container(
                    color: AppColors.brandSoft,
                    alignment: Alignment.center,
                    child: Text(
                      initialOf(a.nameBn),
                      style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.brand),
                    ),
                  )
                : CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover, errorWidget: (_, _, _) => Container(color: AppColors.sunk)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.nameBn, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (a.rankBn != null) Pill(a.rankBn!),
                  const Pill('সংসদ সদস্য নন', colour: AppColors.muted),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _posts(BuildContext context, List<AdviserPost> posts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('দায়িত্ব', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final p in posts)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: 8),
                    child: Icon(Icons.circle, size: 6, color: AppColors.brand),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.ministryBn ?? p.title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        if (dateBn(p.fromDate) != null)
                          Text('${dateBn(p.fromDate)} থেকে', style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
