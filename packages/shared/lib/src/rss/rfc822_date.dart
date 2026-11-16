const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _namedZoneOffsetHours = {
  'GMT': 0,
  'UT': 0,
  'UTC': 0,
  'Z': 0,
  'EST': -5,
  'EDT': -4,
  'CST': -6,
  'CDT': -5,
  'MST': -7,
  'MDT': -6,
  'PST': -8,
  'PDT': -7,
};

final _pattern = RegExp(
  r'^(?:(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),\s*)?(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?\s+(\S+)$',
);

/// RFC 822 形式の日付文字列を UTC の [DateTime] に変換する。解釈できない場合は null。
DateTime? parseRfc822Date(String value) {
  final match = _pattern.firstMatch(value.trim());
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = _months.indexOf(match.group(2)!) + 1;
  if (month == 0) return null;
  final year = int.parse(match.group(3)!);
  if (day < 1 || day > _daysInMonth(year, month)) return null;
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6) ?? '0');
  if (hour > 23 || minute > 59 || second > 59) return null;
  final offset = _offsetOf(match.group(7)!);
  if (offset == null) return null;
  return DateTime.utc(year, month, day, hour, minute, second).subtract(offset);
}

Duration? _offsetOf(String zone) {
  final numeric = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(zone);
  if (numeric != null) {
    final sign = numeric.group(1) == '-' ? -1 : 1;
    final minutes =
        int.parse(numeric.group(2)!) * 60 + int.parse(numeric.group(3)!);
    return Duration(minutes: sign * minutes);
  }
  final hours = _namedZoneOffsetHours[zone];
  return hours == null ? null : Duration(hours: hours);
}

int _daysInMonth(int year, int month) {
  // 翌月 0 日 = 当月末日。DateTime.utc の繰り上げを利用して日数を求める。
  return DateTime.utc(year, month + 1, 0).day;
}
