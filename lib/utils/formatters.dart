/// 日期与文案格式化。
///
/// 纯函数、不依赖 Flutter，单测直接覆盖。日期一律按「本地挂钟时间」算，
/// 跨夏令时用 [DateTime] 的日历构造（自动处理月末与 23/25 小时的一天）。
library;

const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

const List<String> _cnDigits = [
  '零',
  '一',
  '二',
  '三',
  '四',
  '五',
  '六',
  '七',
  '八',
  '九',
  '十',
];

const List<String> _cnMonths = [
  '一',
  '二',
  '三',
  '四',
  '五',
  '六',
  '七',
  '八',
  '九',
  '十',
  '十一',
  '十二',
];

/// 去掉时分秒毫秒，只留日期。
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 加减天数，按日历走（`DateTime(2026, 2, 30)` 会正确滚到 3 月）。
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// 该日期所在周的周一（本地 00:00）。
DateTime mondayOf(DateTime d) {
  final day = dateOnly(d);
  return addDays(day, -(day.weekday - DateTime.monday));
}

/// 是否同一天（只比较年月日）。
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 纯日期差（用 UTC 计算，不受夏令时影响）。
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// "10 月 25 日"
String monthDay(DateTime d) => '${d.month} 月 ${d.day} 日';

/// "10.25" —— 柱状图日期轴、周区间用。
String dotDate(DateTime d) => '${d.month}.${d.day}';

/// 周几的简称，周一为 "一"、周日为 "日"。
String weekdayShort(int weekday) =>
    _weekdays[(weekday - DateTime.monday).clamp(0, 6)];

/// "10 月 30 日 · 周五"
String dayKicker(DateTime d) => '${monthDay(d)} · 周${weekdayShort(d.weekday)}';

/// "10.23 – 10.29"
String weekRange(DateTime weekStart) =>
    '${dotDate(dateOnly(weekStart))} – ${dotDate(addDays(weekStart, 6))}';

/// 1–10 用汉字，其余直接用数字（"五" / "14"）。
String cnNumber(int n) => (n >= 0 && n <= 10) ? _cnDigits[n] : '$n';

/// 该周归属月份的「第几周」。
///
/// 以「该周周四所在的月份」为准（跨月的周归到占 4 天以上的那一侧），
/// 该月 1 号所在周算第一周。这样 9.28–10.4 记作「十月 · 第一周」。
int weekOfMonth(DateTime weekStart) {
  final thursday = addDays(dateOnly(weekStart), 3);
  final firstMonday = mondayOf(DateTime(thursday.year, thursday.month, 1));
  return daysBetween(firstMonday, weekStart) ~/ 7 + 1;
}

/// "十月 · 第五周"
String weekKicker(DateTime weekStart) {
  final thursday = addDays(dateOnly(weekStart), 3);
  final month = _cnMonths[thursday.month - 1];
  return '$month月 · 第${cnNumber(weekOfMonth(weekStart))}周';
}
