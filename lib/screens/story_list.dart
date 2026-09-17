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
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          );
        }
        if (snap.hasError) {
          return ErrorView(message: '${snap.error}', onRetry: onRetry);
        }
        final stories = snap.data ?? const <Story>[];
        final list = ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePad,
            12,
            AppSizes.pagePad,
            28,
          ),
          itemCount:
              stories.length +
              (header != null ? 1 : 0) +
              (stories.isEmpty ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (header != null && i == 0) return header!;
            final index = i - (header != null ? 1 : 0);
            if (stories.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: Icons.article_outlined,
                  title: emptyTitle,
                  body: emptyBody,
                ),
              );
            }
            return StoryCard(story: stories[index]);
          },
        );
        return onRefresh == null
            ? list
            : RefreshIndicator(
                color: AppColors.brand,
                onRefresh: onRefresh!,
                child: list,
              );
      },
    );
  }
}

/// One headline: the outlet and when, the headline, the members it names, and
/// the outlet's picture on the right where it published one. A picture that
/// will not load shows the outlet's initial instead of an empty grey box.
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

    return Container(
      decoration: AppDecor.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(story.lead.url),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (story.isVideo) ...[
                            const Icon(
                              Icons.play_circle_fill_rounded,
                              size: 15,
                              color: Color(0xFFE62117),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Flexible(
                            child: Text(
                              story.lead.source,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'NotoSansBengali',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (when.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.circle,
                                size: 3.5,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              when,
                              style: const TextStyle(
                                fontFamily: 'NotoSansBengali',
                                fontSize: 12,
                                color: AppColors.muted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        story.lead.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'NotoSansBengali',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          height: 1.45,
                        ),
                      ),
                      if (story.members.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            for (final m in story.members.take(2))
                              PartyChip(
                                abbr: m.party,
                                label: m.name,
                                compact: true,
                              ),
                          ],
                        ),
                      ],
                      if (story.also.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'আরও ${bn(story.also.length)}টি সংবাদমাধ্যমে',
                          style: const TextStyle(
                            fontFamily: 'NotoSansBengali',
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (story.thumbnail != null || story.isVideo) ...[
                  const SizedBox(width: 12),
                  _thumbnail(length),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _monogram() {
    final letter = story.lead.source.isEmpty
        ? '•'
        : story.lead.source.characters.first;
    return Container(
      color: AppColors.brandSoft,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontFamily: 'NotoSansBengali',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.brand,
        ),
      ),
    );
  }

  Widget _thumbnail(String? length) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        height: 76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (story.thumbnail != null)
              CachedNetworkImage(
                imageUrl: story.thumbnail!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.sunk),
                errorWidget: (_, _, _) => _monogram(),
              )
            else
              _monogram(),
            if (story.isVideo)
              Container(
                color: Colors.black.withValues(alpha: 0.18),
                alignment: Alignment.center,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 19,
                    color: Color(0xFFE62117),
                  ),
                ),
              ),
            if (length != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    length,
                    style: const TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
