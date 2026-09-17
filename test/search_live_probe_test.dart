// Exploratory probe against a saved bootstrap; skipped unless MYMP_BOOTSTRAP is set.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mymp/models.dart';
import 'package:mymp/search.dart';

void main() {
  final path = Platform.environment['MYMP_BOOTSTRAP'];
  test('probe', () {
    final b = Bootstrap.fromJson(
      jsonDecode(File(path!).readAsStringSync()) as Map<String, dynamic>,
    );
    final s = MemberSearch(
      b.members,
      partyNames: {for (final p in b.parties) p.abbr: p.nameBn},
    );
    for (final q in const [
      'tarek', 'tarique rahman', 'tareq', 'তারেক', 'তারেক রহমান', 'rahman', //
      'hossain', 'hussain', 'হোসেন', 'shafiqur', 'safiqur', 'শফিকুর', //
      'nawshad', 'noushad', 'নওশাদ', 'zamir', 'jamir', 'kayser kamal', //
      'dhaka 17',
      'ঢাকা ১৭',
      'ঢাকা-১৭',
      'panchagarh',
      'পঞ্চগড়',
      'bogura',
      'bogra', //
      'chowdhury', 'choudhury', 'চৌধুরী', 'md tarek', 'মোঃ আব্দুস সালাম', //
      'amir khosru',
      'amir khasru',
      'mirza abbas',
      'মির্জা আব্বাস',
      'salahuddin', //
      'tetulia', 'তেঁতুলিয়া', 'bnp', 'jamaat', 'ncp', 'ishraque', 'ishrak', //
      'rumeen',
      'rumin farhana',
      'nurul haque nur',
      'hasnat',
      'sarjis',
      'nahid', //
      'প্রতিমন্ত্রী',
      'স্বরাষ্ট্র',
      'sylhet 1',
      'cox',
      'coxs bazar',
      'কক্সবাজার',
      'xyzqw',
    ]) {
      final r = s.search(q);
      // ignore: avoid_print
      print(
        '${q.padRight(22)} ${r.length.toString().padLeft(3)}  ${r.take(4).map((m) => '${m.nameBn} (${m.seatLabel})').join(' | ')}',
      );
    }
  }, skip: path == null);
}
