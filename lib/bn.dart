/// Bengali numerals and dates. The app is read in Bangla, so ৩৪৮ is the number
/// a reader expects to see, not 348.
const _digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

String bn(Object n) => n.toString().replaceAllMapped(
  RegExp(r'\d'),
  (m) => _digits[int.parse(m[0]!)],
);

/// "১২,৭৭,১১,৮৯৯": thousands, then lakh and crore groups, as Bangla readers count.
String bnGroup(int n) {
  final neg = n < 0;
  var digits = n.abs().toString();
  var out = '';
  if (digits.length > 3) {
    out = ',${digits.substring(digits.length - 3)}';
    digits = digits.substring(0, digits.length - 3);
    while (digits.length > 2) {
      out = ',${digits.substring(digits.length - 2)}$out';
      digits = digits.substring(0, digits.length - 2);
    }
    out = '$digits$out';
  } else {
    out = digits;
  }
  return bn('${neg ? '-' : ''}$out');
}

/// "৫০.৪%" for a share of a whole, one decimal.
String pctBn(num part, num whole) =>
    whole <= 0 ? '০%' : '${bn((part * 100 / whole).toStringAsFixed(1))}%';

const monthsBn = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

const weekdaysBn = [
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
  'রবিবার',
];

/// "১৩ সেপ্টেম্বর ২০২৬" from an ISO date, or null when there is nothing to show.
String? dateBn(String? iso) {
  if (iso == null || iso.length < 10) return null;
  final d = DateTime.tryParse(iso);
  if (d == null) return null;
  return '${bn(d.day)} ${monthsBn[d.month - 1]} ${bn(d.year)}';
}

/// "২ ঘণ্টা আগে" for something today, a date for anything older.
String whenBn(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final then = DateTime.tryParse(iso);
  if (then == null) return '';
  final minutes = DateTime.now().difference(then.toLocal()).inMinutes;
  if (minutes < 1) return 'এইমাত্র';
  if (minutes < 60) return '${bn(minutes)} মিনিট আগে';
  if (minutes < 24 * 60) return '${bn(minutes ~/ 60)} ঘণ্টা আগে';
  return dateBn(iso) ?? '';
}

/// "১২:০৫" from a number of seconds, for a video's length.
String? durationBn(int? seconds) {
  if (seconds == null || seconds <= 0) return null;
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '${bn(m)}:${bn(s)}';
}

/// The date as a card has room for it: today and yesterday by name, then the
/// day and month, and the year only once it is not this one.
String shortDateBn(String? iso, {String? label}) {
  final d = iso == null ? null : DateTime.tryParse(iso);
  if (d == null) {
    // Fall back to the website's own label, minus the weekday it starts with.
    final l = label ?? '';
    return l.contains(',') ? l.split(',').last.trim() : l;
  }
  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (days == 0) return 'আজ';
  if (days == 1) return 'গতকাল';
  final base = '${bn(d.day)} ${monthsBn[d.month - 1]}';
  return d.year == now.year ? base : '$base ${bn(d.year)}';
}

/// The letter drawn in place of a missing photograph.
String initialOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  // Bengali names often start with an honorific the reader does not think of
  // as part of the name; the first real word is the one to take a letter from.
  const skip = {
    'মোঃ',
    'মো.',
    'মোহাম্মদ',
    'মুহাম্মদ',
    'ডাঃ',
    'ডা.',
    'ব্যারিস্টার',
    'অ্যাডভোকেট',
    'এড.',
  };
  for (final word in trimmed.split(RegExp(r'\s+'))) {
    if (!skip.contains(word) && word.isNotEmpty) return word.characters0;
  }
  return trimmed.characters0;
}

extension on String {
  /// The first user-perceived character: a Bengali letter plus its vowel signs.
  String get characters0 {
    if (isEmpty) return '?';
    var end = 1;
    while (end < length && RegExp(r'[া-্ৗ‌‍]').hasMatch(this[end])) {
      end++;
    }
    return substring(0, end);
  }
}

/// A parliament by its Bangla ordinal, as the secretariat writes it: ত্রয়োদশ, not ১৩তম.
String parliamentBn(int n) {
  const words = {
    1: 'প্রথম',
    2: 'দ্বিতীয়',
    3: 'তৃতীয়',
    4: 'চতুর্থ',
    5: 'পঞ্চম',
    6: 'ষষ্ঠ',
    7: 'সপ্তম',
    8: 'অষ্টম',
    9: 'নবম',
    10: 'দশম',
    11: 'একাদশ',
    12: 'দ্বাদশ',
    13: 'ত্রয়োদশ',
    14: 'চতুর্দশ',
    15: 'পঞ্চদশ',
  };
  return words[n] ?? '${bn(n)}তম';
}
