import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paper_todo/data/todo_store.dart';
import 'package:paper_todo/main.dart';
import 'package:paper_todo/models/todo_note.dart';
import 'package:paper_todo/state/todo_controller.dart';
import 'package:paper_todo/widgets/later_note_tile.dart';

/// 固定时钟：2026-10-30 周五 09:00，「想到几天前」才可断言。
DateTime get _clock => DateTime(2026, 10, 30, 9);

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

Future<void> _openLater(WidgetTester tester) async {
  await tester.tap(find.text('以后'));
  await tester.pumpAndSettle();
}

TodoNote _note({
  required String id,
  required String content,
  TodoCategory category = TodoCategory.life,
  int daysAgo = 2,
  TodoBucket bucket = TodoBucket.later,
}) => TodoNote(
  id: id,
  content: content,
  category: category,
  createdAt: _clock.subtract(Duration(days: daysAgo)),
  bucket: bucket,
);

List<TodoNote> _laterSeed() => [
  ..._laterOnly(),
  _note(
    id: 't1',
    content: '今天要开的会',
    category: TodoCategory.work,
    daysAgo: 0,
    bucket: TodoBucket.today,
  ),
];

List<TodoNote> _laterOnly() => [
  _note(id: 'l1', content: '学做一次手冲咖啡', daysAgo: 2),
  _note(
    id: 'l2',
    content: '读完《人类简史》',
    category: TodoCategory.study,
    daysAgo: 7,
  ),
];

void main() {
  testWidgets('以后页列出放着的事，按想到的时间倒序，今天的事不出现', (tester) async {
    await _pumpApp(tester, seed: _laterSeed());
    await _openLater(tester);

    expect(find.text('不着急的事，\n放这里'), findsOneWidget);
    expect(find.text('放着的 2 件'), findsOneWidget);
    expect(find.byType(LaterNoteTile), findsNWidgets(2));

    expect(find.text('学做一次手冲咖啡'), findsOneWidget);
    expect(find.text('想到 2 天前'), findsOneWidget);
    expect(find.text('读完《人类简史》'), findsOneWidget);
    expect(find.text('想到 1 周前'), findsOneWidget);

    // 今天那栏的事不会跑到以后来。
    expect(find.text('今天要开的会'), findsNothing);

    // 想到得越晚越靠上。
    final tiles = tester
        .widgetList<LaterNoteTile>(find.byType(LaterNoteTile))
        .toList();
    expect(tiles.first.note.id, 'l1');
  });

  testWidgets('写一行点「先记着」，存进以后并出现在最上面', (tester) async {
    final controller = await _pumpApp(tester, seed: _laterSeed());
    await _openLater(tester);

    await tester.enterText(find.byType(TextField), '给爸妈打个长电话');
    await tester.pump();
    await tester.tap(find.text('工作'));
    await tester.pump();
    await tester.tap(find.text('先记着'));
    await tester.pump();

    expect(find.text('记在「以后」了'), findsOneWidget);
    expect(controller.later, hasLength(3));
    expect(controller.later.first.content, '给爸妈打个长电话');
    expect(controller.later.first.category, TodoCategory.work);
    expect(controller.later.first.bucket, TodoBucket.later);
    expect(controller.pending.map((n) => n.id), ['t1']);

    // 输入框清空，可以接着写下一条。
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    expect(find.text('放着的 3 件'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('点「挪到今天」后从以后消失、进今天，提示条可撤销', (tester) async {
    final controller = await _pumpApp(tester, seed: _laterOnly());
    await _openLater(tester);

    await tester.tap(find.byTooltip('挪到今天').first);
    // 等提示条滑上来再点「撤销」，否则按到的是动画途中的位置。
    await tester.pumpAndSettle();

    expect(find.text('挪到今天了'), findsOneWidget);
    expect(controller.later.map((n) => n.id), ['l2']);
    expect(controller.pending.map((n) => n.id), ['l1']);
    expect(find.text('放着的 1 件'), findsOneWidget);
    expect(find.text('学做一次手冲咖啡'), findsNothing);

    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();

    expect(controller.later.map((n) => n.id), contains('l1'));
    expect(controller.pending, isEmpty);
    expect(find.text('学做一次手冲咖啡'), findsOneWidget);
  });

  testWidgets('点一行进编辑，改完仍留在以后', (tester) async {
    final controller = await _pumpApp(tester, seed: _laterOnly());
    await _openLater(tester);

    await tester.tap(find.text('学做一次手冲咖啡'));
    await tester.pumpAndSettle();
    expect(find.text('编辑这条待办'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '学做一次手冲咖啡和拉花');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(controller.later, hasLength(2));
    expect(controller.later.map((n) => n.content), contains('学做一次手冲咖啡和拉花'));
    expect(controller.pending, isEmpty);
    expect(find.text('学做一次手冲咖啡和拉花'), findsOneWidget);
  });

  testWidgets('没有放着的事时给空态，「先记着」点不动', (tester) async {
    final controller = await _pumpApp(tester);
    await _openLater(tester);

    expect(find.text('放着的 0 件'), findsOneWidget);
    expect(find.text('还没放什么事。'), findsOneWidget);
    expect(find.text('想起什么，在上面写一行先记着。'), findsOneWidget);

    await tester.tap(find.text('先记着'));
    await tester.pump();
    expect(controller.all, isEmpty);
    expect(find.text('记在「以后」了'), findsNothing);
  });

  testWidgets('底栏切到以后、再切回今天', (tester) async {
    await _pumpApp(tester, seed: _laterOnly());
    await _openLater(tester);
    expect(find.text('不着急的事，\n放这里'), findsOneWidget);

    await tester.tap(find.text('今天'));
    await tester.pumpAndSettle();
    expect(find.text('今天\n想做什么？'), findsOneWidget);
    expect(find.text('今天没有安排。'), findsOneWidget);
    expect(find.text('去「以后」翻翻，或点 + 写一条。'), findsOneWidget);
  });

  testWidgets('窄屏 320×640、字号 1.3 倍下不溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpApp(tester, seed: _laterSeed(), size: const Size(320, 640));
    await _openLater(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('不着急的事，\n放这里'), findsOneWidget);

    // 窄屏上纸条更高，把清单滚进视野再断言。
    await tester.scrollUntilVisible(
      find.text('放着的 2 件'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('放着的 2 件'), findsOneWidget);
  });
}
