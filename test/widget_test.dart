import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mymp/bn.dart';
import 'package:mymp/models.dart';
import 'package:mymp/widgets.dart';

void main() {
  group('Bengali text', () {
    test('numbers are written in Bengali digits', () {
      expect(bn(348), '৩৪৮');
      expect(bn(13), '১৩');
      expect(bn('2026-09-13'), '২০২৬-০৯-১৩');
    });

    test('a date reads the way a Bengali reader writes it', () {
      expect(dateBn('2026-09-13'), '১৩ সেপ্টেম্বর ২০২৬');
      expect(dateBn(null), isNull);
      expect(dateBn('not a date'), isNull);
    });

    test('a video length is minutes and seconds, zero-padded', () {
      expect(durationBn(125), '২:০৫');
      expect(durationBn(0), isNull);
      expect(durationBn(null), isNull);
    });

    test('the avatar letter skips an honorific and keeps the vowel sign', () {
      // "মোঃ আবুল হাসনাত" is filed under আ, not মো: the honorific is not part
      // of the name as a reader thinks of it.
      expect(initialOf('মোঃ আবুল হাসনাত'), 'আ');
      expect(initialOf('তারেক রহমান'), 'তা');
      expect(initialOf(''), '?');
    });
  });

  group('parsing what the site sends', () {
    test('a member survives missing fields', () {
      final m = MemberBrief.fromJson(const {
        'id': '1',
        'slug': 'x',
        'nameBn': 'ক খ',
      });
      expect(m.nameBn, 'ক খ');
      expect(m.photoUrl, isNull);
      expect(m.seatLabel, 'সংরক্ষিত আসন');
    });

    test('a story takes either one member or several', () {
      final one = Story.fromJson(const {
        'id': 'a',
        'lead': {
          'title': 'শিরোনাম',
          'source': 'প্রথম আলো',
          'url': 'https://example.com',
        },
        'member': {'slug': 's', 'name': 'ক খ'},
      });
      expect(one.members.single.name, 'ক খ');

      final many = Story.fromJson(const {
        'id': 'b',
        'lead': {
          'title': 'শিরোনাম',
          'source': 'সমকাল',
          'url': 'https://example.com',
        },
        'members': [
          {'slug': 's1', 'name': 'ক'},
          {'slug': 's2', 'name': 'খ'},
        ],
        'kind': 'video',
      });
      expect(many.members.length, 2);
      expect(many.isVideo, isTrue);
    });

    test('an unexpected shape does not throw', () {
      expect(() => Story.fromJson(const {'id': 'c'}), returnsNormally);
      expect(() => Bootstrap.fromJson(const {}), returnsNormally);
    });
  });

  testWidgets('a member tile shows the name, the seat and the office', (
    tester,
  ) async {
    const member = MemberBrief(
      id: '013025201',
      slug: 'hasnat-abdullah',
      nameBn: 'মোঃ আবুল হাসনাত',
      party: 'NCP',
      seatNo: 252,
      seatBn: 'কুমিল্লা-৪',
      officeBn: 'প্রধানমন্ত্রী',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberTile(member: member, onTap: () {}),
        ),
      ),
    );

    expect(find.text('মোঃ আবুল হাসনাত'), findsOneWidget);
    expect(find.text('কুমিল্লা-৪'), findsOneWidget);
    expect(find.text('প্রধানমন্ত্রী'), findsOneWidget);
  });
}
