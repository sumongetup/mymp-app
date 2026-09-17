import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'story_list.dart';
import 'video_strip.dart';

/// The whole house's news: every headline and video the site has attached to a
/// member, newest first, with a filter for news or videos alone. The unfiltered
/// view opens with a row of the newest member videos, as the website's home does.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String? _type;
  late Future<List<Story>> _future = Api.instance.news(type: 'news');
  late Future<List<Story>> _videos = Api.instance.news(type: 'video', limit: 30);

  void _load({String? type}) {
    setState(() {
      _type = type;
      // "সব" shows the video row and then the news; the video chip shows videos only.
      _future = Api.instance.news(type: type ?? 'news');
      if (type == null) _videos = Api.instance.news(type: 'video', limit: 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.pagePad, 10, AppSizes.pagePad, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('সংবাদ', style: Theme.of(context).textTheme.displaySmall),
                        Text(
                          'সংসদ সদস্যদের নিয়ে সংবাদমাধ্যমের শিরোনাম ও ভিডিও',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ChipBar(
              options: const [
                (label: 'সব', value: null),
                (label: 'সংবাদ', value: 'news'),
                (label: 'ভিডিও', value: 'video'),
              ],
              selected: _type,
              onSelect: (v) => _load(type: v),
            ),
            Expanded(
              child: StoryList(
                future: _future,
                header: _type == null
                    ? FutureBuilder<List<Story>>(
                        future: _videos,
                        // The row is extra: if videos fail to load, the news below still shows.
                        builder: (context, snap) => snap.hasData
                            ? VideoStrip(videos: snap.data!, onSeeAll: () => _load(type: 'video'))
                            : const SizedBox.shrink(),
                      )
                    : null,
                emptyTitle: 'এখন কোনো খবর নেই',
                emptyBody: 'নতুন শিরোনাম এলে এখানে দেখা যাবে।',
                onRetry: () => _load(type: _type),
                onRefresh: () async => _load(type: _type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
