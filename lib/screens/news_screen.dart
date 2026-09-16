import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'story_list.dart';

/// The whole house's news: every headline and video the site has attached to a
/// member, newest first, with a filter for videos alone.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String? _type;
  late Future<List<Story>> _future = Api.instance.news();

  void _load({String? type}) {
    setState(() {
      _type = type;
      _future = Api.instance.news(type: type);
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
