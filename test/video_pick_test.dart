import 'package:flutter_test/flutter_test.dart';
import 'package:mymp/models.dart';
import 'package:mymp/screens/video_strip.dart';

Story _video(String id, String title, String member, {bool picture = true}) =>
    Story(
      id: id,
      date: '2026-09-17',
      dateLabel: '',
      lead: StoryLink(
        title: title,
        url: 'https://youtube.com/watch?v=$id',
        source: 'চ্যানেল',
      ),
      members: [StoryMember(slug: member, name: member)],
      kind: 'video',
      thumbnail: picture ? 'https://i.ytimg.com/vi/$id/hqdefault.jpg' : null,
    );

void main() {
  test(
    'videos about a member come before bulletins, at most two per member, only with a picture',
    () {
      final picked = pickVideos([
        _video('a', 'Latest News Headlines | 8 AM', 'pm'),
        _video('b', 'প্রধানমন্ত্রীর বক্তব্য', 'pm'),
        _video('c', 'প্রধানমন্ত্রীর সফর', 'pm'),
        _video('d', 'প্রধানমন্ত্রীর সভা', 'pm'),
        _video('e', 'এলাকার উন্নয়ন', 'mp2'),
        _video('f', 'ছবি নেই', 'mp3', picture: false),
      ]);
      expect(picked.map((v) => v.id), ['b', 'c', 'e']);
    },
  );
}
