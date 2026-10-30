import 'package:flutter_test/flutter_test.dart';
import 'package:paper_todo/utils/formatters.dart';

void main() {
  test('mondayOf 取所在周的周一，周一返回自己', () {
    expect(mondayOf(DateTime(2026, 10, 30, 15)), DateTime(2026, 10, 26));
    expect(mondayOf(DateTime(2026, 10, 26, 0, 5)), DateTime(2026, 10, 26));
    expect(mondayOf(DateTime(2026, 10, 25)), DateTime(2026, 10, 19)); // 周日属上一周
  });

  test('addDays 跨月，dateOnly 去掉时分秒', () {
    expect(addDays(DateTime(2026, 10, 31), 1), DateTime(2026, 11, 1));
    expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    expect(
      dateOnly(DateTime(2026, 10, 30, 23, 59, 59)),
      DateTime(2026, 10, 30),
    );
  });

  test('isSameDay / daysBetween', () {
    expect(
      isSameDay(DateTime(2026, 10, 30, 8), DateTime(2026, 10, 30, 22)),
      isTrue,
    );
    expect(
      isSameDay(DateTime(2026, 10, 30, 8), DateTime(2026, 10, 31, 1)),
      isFalse,
    );
    expect(daysBetween(DateTime(2026, 10, 26), DateTime(2026, 11, 1)), 6);
  });

  test('dayKicker / monthDay / weekRange', () {
    expect(dayKicker(DateTime(2026, 10, 30)), '10 月 30 日 · 周五');
    expect(dayKicker(DateTime(2026, 11, 1)), '11 月 1 日 · 周日');
    expect(monthDay(DateTime(2026, 10, 25)), '10 月 25 日');
    expect(weekRange(DateTime(2026, 10, 26)), '10.26 – 11.1');
  });

  test('weekdayShort 周一到周日', () {
    expect([for (var d = 1; d <= 7; d++) weekdayShort(d)].join(), '一二三四五六日');
  });

  test('cnNumber 1–10 用汉字，其余用数字', () {
    expect(cnNumber(0), '零');
    expect(cnNumber(5), '五');
    expect(cnNumber(10), '十');
    expect(cnNumber(11), '11');
    expect(cnNumber(14), '14');
  });

  test('weekOfMonth / weekKicker 按「周四所在月份」归属', () {
    // 2026-10-01 是周四，9-28 那周算十月第一周；10-01 之后每周递增。
    expect(weekOfMonth(DateTime(2026, 9, 28)), 1);
    expect(weekOfMonth(DateTime(2026, 10, 5)), 2);
    expect(weekOfMonth(DateTime(2026, 10, 26)), 5);
    expect(weekKicker(DateTime(2026, 9, 28)), '十月 · 第一周');
    expect(weekKicker(DateTime(2026, 10, 26)), '十月 · 第五周');
  });
}
