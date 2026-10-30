import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paper_todo/data/todo_store.dart';
import 'package:paper_todo/main.dart';
import 'package:paper_todo/models/todo_note.dart';
import 'package:paper_todo/state/todo_controller.dart';
import 'package:paper_todo/widgets/day_bar_chart.dart';

/// 固定时钟（2026-10-30 周五），周一是 10-26，本周范围 10.26 – 11.01。
DateTime get _clock => DateTime(2026, 10, 30, 9);

TodoNote _done({
  required String id,
  required String content,
  required DateTime completedAt,
  String? estimateLabel,
}) => TodoNote(
  id: id,
  content: content,
  category: TodoCategory.work,
  estimateLabel: estimateLabel,
  createdAt: completedAt.subtract(const Duration(hours: 2)),
  completedAt: completedAt,
);

/// 本周：周一 3 件、周三 1 件、今天（周五）2 件，共 6 件。
List<TodoNote> _weekSeed() => [
  _done(
    id: 'a1',
    content: '周一例会',
    completedAt: DateTime(2026, 10, 26, 10),
    estimateLabel: '1 小时',
  ),
  _done(
    id: 'a2',
    content: '周一写周报',
    completedAt: DateTime(2026, 10, 26, 15),
    estimateLabel: '30 分钟',
  ),
  _done(id: 'a3', content: '周一回邮件', completedAt: DateTime(2026, 10, 26, 17)),
  _done(
    id: 'b1',
    content: '周三改稿',
    completedAt: DateTime(2026, 10, 28, 11),
    estimateLabel: '2 小时',
  ),
  _done(
    id: 'c1',
    content: '今天审 PR',
    completedAt: DateTime(2026, 10, 30, 8),
    estimateLabel: '30 分钟',
  ),
  _done(id: 'c2', content: '今天写提纲', completedAt: DateTime(2026, 10, 30, 9)),
];

Future<TodoController> _pumpApp(
  WidgetTester tester, {
  List<TodoNote> seed = const <TodoNote>[],
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final controller = TodoController(
    MemoryTodoStore(seed),
    now: () => _clock,
    saveDebounce: const Duration(milliseconds: 10),
  );
  await controller.load();
  await tester.pumpWidget(TodoApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _openStats(WidgetTester tester) async {
  await tester.tap(find.text('回顾'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('本周总览：标题、完成件数、连续记录、默认选中完成最多的一天', (tester) async {
    await _pumpApp(tester, seed: _weekSeed());
    await _openStats(tester);

    expect(find.text('十月 · 第五周'), findsOneWidget);
    expect(find.text('这周完成了 6 件'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('连续记录'), findsOneWidget);
    // 今天完成过，连续记录 1 天。
    expect(find.text('1'), findsOneWidget);

    // 默认选中周一（3 件）：明细卡标题与行数跟着走。
    expect(find.text('10 月 26 日 · 周一'), findsOneWidget);
    expect(find.text('3 件'), findsOneWidget);
    expect(find.text('周一例会'), findsOneWidget);
  });

  testWidgets('点柱子切换明细，显示那天的条目与预计花费', (tester) async {
    await _pumpApp(tester, seed: _weekSeed());
    await _openStats(tester);

    final chart = tester.getRect(find.byType(DayBarChart));
    // 第 5 根柱（索引 4 = 周五）。
    await tester.tapAt(
      Offset(chart.left + chart.width * (4.5 / 7), chart.center.dy),
    );
    await tester.pumpAndSettle();

    expect(find.text('10 月 30 日 · 周五'), findsOneWidget);
    expect(find.text('今天审 PR'), findsOneWidget);
    expect(find.text('30 分钟'), findsOneWidget);
    // 没填预计花费的那条回落到分类名。
    expect(find.text('今天写提纲'), findsOneWidget);
    expect(find.text('工作'), findsOneWidget);
  });

  testWidgets('空周：图表为 0，明细区给空状态提示', (tester) async {
    await _pumpApp(tester);
    await _openStats(tester);

    expect(find.text('这周完成了 0 件'), findsOneWidget);
    expect(find.text('这一周还没有完成记录。'), findsOneWidget);
  });

  testWidgets('换一周：弹层选上一周后标题、件数、明细都更新', (tester) async {
    await _pumpApp(tester, seed: _weekSeed());
    await _openStats(tester);

    await tester.tap(find.text('换一周'));
    await tester.pumpAndSettle();

    // 弹层头是 2026 年 10 月，选中行是 10.26 – 11.01。
    expect(find.text('2026 年 10 月'), findsOneWidget);
    expect(find.text('已选 10.26 – 11.1 · 本周 6 件'), findsOneWidget);

    // 点上一周那一行（10.19 – 10.25 的 19 日），页脚跟着变。
    await tester.tap(find.text('19'));
    await tester.pumpAndSettle();
    expect(find.text('已选 10.19 – 10.25 · 本周 0 件'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '完成'));
    await tester.pumpAndSettle();

    expect(find.text('十月 · 第四周'), findsOneWidget);
    expect(find.text('这周完成了 0 件'), findsOneWidget);
  });

  testWidgets('弹层点标题切年月选择，选 11 月回到 11 月日历', (tester) async {
    await _pumpApp(tester, seed: _weekSeed());
    await _openStats(tester);

    await tester.tap(find.text('换一周'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026 年 10 月'));
    await tester.pumpAndSettle();

    expect(find.text('2026 年'), findsOneWidget);
    await tester.tap(find.text('11 月'));
    await tester.pumpAndSettle();

    expect(find.text('2026 年 11 月'), findsOneWidget);
  });

  testWidgets('窄屏 320×640 回顾页不溢出', (tester) async {
    await _pumpApp(tester, seed: _weekSeed(), size: const Size(320, 640));
    await _openStats(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('这周完成了 6 件'), findsOneWidget);
  });
}
