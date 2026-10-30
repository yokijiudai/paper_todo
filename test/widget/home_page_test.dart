import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:node/data/todo_store.dart';
import 'package:node/main.dart';
import 'package:node/models/todo_note.dart';
import 'package:node/state/todo_controller.dart';
import 'package:node/widgets/check_circle.dart';
import 'package:node/widgets/note_tile.dart';

/// 固定时钟：2026-10-30 是周五，避免「今天」在不同日期跑测试时漂移。
DateTime get _clock => DateTime(2026, 10, 30, 9);

Future<TodoController> _pumpApp(
  WidgetTester tester, {
  List<TodoNote> seed = const <TodoNote>[],
  Size size = const Size(390, 844),
}) async {
  // 默认按目标机型 390×844 渲染，下面的两段内容才都进得了视野。
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

List<TodoNote> _seedNotes() {
  final day = DateTime(2026, 10, 30);
  return [
    TodoNote(
      id: 'a',
      content: '团队例会',
      category: TodoCategory.work,
      estimateLabel: '1 小时',
      createdAt: day.add(const Duration(hours: 9, minutes: 20)),
    ),
    TodoNote(
      id: 'b',
      content: '审阅新功能分支的 PR',
      category: TodoCategory.work,
      createdAt: day.add(const Duration(hours: 9, minutes: 5)),
    ),
    TodoNote(
      id: 'c',
      content: '给阳台的琴叶榕换盆',
      category: TodoCategory.life,
      createdAt: day.add(const Duration(hours: 8, minutes: 40)),
    ),
    TodoNote(
      id: 'd',
      content: '写完 Q4 项目提案的提纲',
      category: TodoCategory.work,
      estimateLabel: '1 小时',
      createdAt: day.add(const Duration(hours: 8)),
      completedAt: day.add(const Duration(hours: 10, minutes: 30)),
    ),
  ];
}

void main() {
  testWidgets('首页渲染未完成与今天已完成两段', (tester) async {
    await _pumpApp(tester, seed: _seedNotes());

    expect(find.text('今天要做的\n三件事'), findsOneWidget);
    expect(find.text('已完成 1 件 · 还有 3 件'), findsOneWidget);
    expect(find.text('未完成'), findsOneWidget);
    expect(find.text('今天已完成'), findsOneWidget);
    expect(find.text('团队例会'), findsOneWidget);
    expect(find.text('写完 Q4 项目提案的提纲'), findsOneWidget);
  });

  testWidgets('勾选一条后计数与分段同步更新', (tester) async {
    final controller = await _pumpApp(tester, seed: _seedNotes());

    expect(controller.pending.length, 3);
    await tester.tap(find.byType(CheckCircle).first);
    await tester.pumpAndSettle();

    expect(controller.pending.length, 2);
    expect(find.text('已完成 2 件 · 还有 2 件'), findsOneWidget);
    // 刚勾完的那条挪进了「今天已完成」，两段都还看得见它。
    expect(find.byType(NoteTile), findsNWidgets(4));
  });

  testWidgets('没有任何待办时显示空态文案', (tester) async {
    await _pumpApp(tester);

    expect(find.text('今天\n想做什么？'), findsOneWidget);
    expect(find.text('还没有待办'), findsOneWidget);
    expect(find.text('现在没有待办。'), findsOneWidget);
    expect(find.text('点下面的 + 写第一条。'), findsOneWidget);
    expect(find.text('今天还没有完成的事。'), findsOneWidget);
  });

  testWidgets('全部做完时标题变成「都做完了」', (tester) async {
    final controller = await _pumpApp(
      tester,
      seed: [
        for (final note in _seedNotes())
          if (note.isCompleted) note,
      ],
    );
    expect(controller.pending, isEmpty);
    expect(find.text('今天的事\n都做完了。'), findsOneWidget);
  });

  testWidgets('窄屏 320×640 下不溢出，长标题会截断', (tester) async {
    await _pumpApp(
      tester,
      size: const Size(320, 640),
      seed: [
        TodoNote(
          id: 'long',
          content: '这是一条很长很长很长的待办，用来验证在窄屏上会折成两行并截断而不是把行撑破',
          category: TodoCategory.study,
          estimateLabel: '30 分钟',
          createdAt: DateTime(2026, 10, 30, 8),
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('今天要做的\n一件事'), findsOneWidget);
  });

  testWidgets('只剩两条未完成时，标题用「两件事」而不是「二件事」', (tester) async {
    await _pumpApp(tester, seed: _seedNotes().take(2).toList());

    expect(find.text('今天要做的\n两件事'), findsOneWidget);
  });

  testWidgets('底部分段可以切到回顾再切回来', (tester) async {
    await _pumpApp(tester, seed: _seedNotes());

    await tester.tap(find.text('回顾'));
    await tester.pumpAndSettle();
    expect(find.text('每天完成的件数'), findsOneWidget);
    expect(find.text('换一周'), findsOneWidget);

    await tester.tap(find.text('今天'));
    await tester.pumpAndSettle();
    expect(find.text('今天要做的\n三件事'), findsOneWidget);
  });
}
