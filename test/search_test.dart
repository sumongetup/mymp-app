import 'package:flutter_test/flutter_test.dart';
import 'package:mymp/models.dart';
import 'package:mymp/search.dart';

MemberBrief _m(
  String id,
  String bn,
  String en,
  String seatBn,
  String seatEn,
  int no, {
  String? area,
  String party = 'BNP',
  String? office,
}) => MemberBrief(
  id: id,
  slug: id,
  nameBn: bn,
  nameEn: en,
  party: party,
  partyBn: party == 'BNP' ? 'বিএনপি' : 'জামায়াতে ইসলামী',
  seatNo: no,
  seatBn: seatBn,
  seatEn: seatEn,
  districtBn: seatBn.split('-').first,
  districtEn: seatEn.split('-').first,
  areaBn: area,
  officeBn: office,
);

void main() {
  final members = [
    _m(
      '1',
      'ব্যারিস্টার মুহাম্মদ নওশাদ জমির',
      'Barrister Muhammad Nawshad Zamir',
      'পঞ্চগড়-১',
      'Panchagarh-1',
      1,
      area: 'পঞ্চগড় সদর, তেঁতুলিয়া এবং আটোয়ারী উপজেলা',
    ),
    _m(
      '2',
      'ফরহাদ হোসেন আজাদ',
      'Forhad Hossain Azad',
      'পঞ্চগড়-২',
      'Panchagarh-2',
      2,
      office: 'পানি সম্পদ প্রতিমন্ত্রী',
    ),
    _m(
      '3',
      'মোঃ হাসান রাজীব প্রধান',
      'Md Hasan Rajib Prodhan',
      'লালমনিরহাট-১',
      'Lalmonirhat-1',
      12,
    ),
    _m(
      '4',
      'তারেক রহমান',
      'Tarique Rahman',
      'ঢাকা-১৭',
      'Dhaka-17',
      190,
      area: 'ওয়ার্ড নং ১৫, ১৮',
    ),
    _m(
      '5',
      'ডাঃ মোঃ শফিকুর রহমান',
      'Dr. Md. Shafiqur Rahman',
      'ঢাকা-১৫',
      'Dhaka-15',
      188,
      party: 'BJEI',
      area: 'ওয়ার্ড নং ১৭',
    ),
    _m(
      '6',
      'আমির খসরু মাহমুদ চৌধুরী',
      'Amir Khosru Mahmud Chowdhury',
      'চট্টগ্রাম-১১',
      'Chattogram-11',
      288,
    ),
  ];
  final search = MemberSearch(members);
  List<String> ids(String q) => search.search(q).map((m) => m.id).toList();

  test('a name in either script and any common spelling', () {
    for (final q in [
      'tarek',
      'tareq',
      'Tarique',
      'তারেক',
      'md tarek',
      'TAREK RAHMAN',
    ]) {
      expect(ids(q).first, '4', reason: q);
    }
    expect(ids('noushad'), ['1']);
    expect(ids('jamir'), ['1']);
    expect(ids('নওশাদ'), ['1']);
    expect(ids('amir khasru'), ['6']);
    expect(ids('choudhury'), ['6']);
  });

  test('the nearer spelling ranks first among sound-alikes', () {
    expect(ids('hossain').first, '2');
    expect(ids('hussain').first, '2');
  });

  test('a seat in either script and either digits, not a ward number', () {
    expect(ids('dhaka 17'), ['4']);
    expect(ids('ঢাকা-১৭'), ['4']);
    expect(ids('ঢাকা ১৭'), ['4']);
    expect(ids('panchagarh'), ['1', '2']);
  });

  test('an upazila finds its member', () {
    expect(ids('tetulia'), ['1']);
    expect(ids('তেঁতুলিয়া'), ['1']);
  });

  test('party and office', () {
    expect(ids('jamaat'), ['5']);
    expect(ids('প্রতিমন্ত্রী'), ['2']);
  });

  test('a title alone or nonsense finds nobody wrongly', () {
    expect(ids('xyzqw'), isEmpty);
    expect(ids(''), isEmpty);
  });
}
