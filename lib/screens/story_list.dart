import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bn.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// A list of headlines and videos, used both on the news tab and inside a
/// member's page. Every item opens the outlet's own page: the app links to the
/// press, it does not reproduce it.
class StoryList extends StatelessWidget {
  final Future<List<Story>> future;
  final String emptyTitle;
  final String emptyBody;
  final VoidCallback onRetry;
  final Widget? header;
  final Future<void> Function()? onRefresh;

  const StoryList({
    super.key,
    required this.future,
    required this.emptyTitle,
    required this.emptyBody,
    required this.onRetry,
    this.header,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Story>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.brand));
        }
        if (snap.hasError) {
          return ErrorView(message: '${snap.error}', onRetry: onRetry);
        }
        final stories = snap.data ?? const <Story>[];
        final list = ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 12, AppSizes.pagePad, 28),
          itemCount: stories.length + (header != null ? 1 : 0) + (stories.isEmpty ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (header != null && i == 0) return header!;
            final index = i - (header != null ? 1 : 0);
            if (stories.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyState(icon: Icons.article_outlined, title: emptyTitle, body: emptyBody),
              );
            }
            return StoryCard(story: stories[index]);
          },
        );
        return onRefresh == null ? list : RefreshIndicator(color: AppColors.brand, onRefresh: onRefresh!, child: list);
      },
    );
  }
}

/// One headline: the outlet, the picture where the outlet published one, the
/// members it names, and the other outlets that ran the same story.
class StoryCard extends StatelessWidget {
  final Story story;
  const StoryCard({super.key, required this.story});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final when = shortDateBn(story.date, label: story.dateLabel);
    final length = durationBn(story.durationSeconds);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: InkWell(
        onTap: () => _open(story.lead.url),
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(color: AppColors.rule),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (story.thumbnail != null || story.isVideo) ...[
                _thumbnail(length),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (story.isVideo) ...[
                          const Pill('ভিডিও'),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            story.lead.source,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (when.isNotEmpty)
                          Text(when, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      story.lead.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.4),
                    ),
                    if (story.members.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          for (final m in story.members.take(3)) PartyChip(abbr: m.party, label: m.name, compact: true),
                        ],
                      ),
                    ],
                    if (story.also.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        'একই খবর আরও ${bn(story.also.length)}টি সংবাদমাধ্যমে',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(String? length) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 104,
        height: 68,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (story.thumbnail != null)
              CachedNetworkImage(
                imageUrl: story.thumbnail!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.sunk),
                errorWidget: (_, _, _) => Container(color: AppColors.sunk),
              )
            else
              Container(color: AppColors.sunk),
            if (story.isVideo)
              Container(
                color: Colors.black.withValues(alpha: 0.22),
                alignment: Alignment.center,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, size: 20, color: AppColors.ink),
                ),
              ),
            if (length != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    length,
                    style: const TextStyle(fontFamily: 'NotoSansBengali', fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
