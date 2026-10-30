import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:node/data/todo_store.dart';
import 'package:node/main.dart';
import 'package:node/models/todo_note.dart';
import 'package:node/state/todo_controller.dart';

/// 固定时钟，避免测试跑在不同日期时「今天」漂移。
DateTime get _clock => DateTime(2026, 10, 30, 9);

Future<TodoController> _pumpApp(
  WidgetTester tester, {
  List<TodoNote> seed = const <TodoNote>[],
}) async {
  tester.view.physicalSize = const Size(390, 844);
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

Future<void> _openNewForm(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add_rounded));
  await tester.pumpAndSettle();
}

TodoNote _editableNote() => TodoNote(
  id: 'edit-1',
  content: '旧内容：给琴叶榕换盆',
  category: TodoCategory.work,
  estimateLabel: '1 小时',
  createdAt: DateTime(2026, 10, 30, 8, 40),
);

void main() {
  testWidgets('新建：填内容、选分类和时间，保存后回到首页', (tester) async {
    final controller = await _pumpApp(tester);
    await _openNewForm(tester);

    expect(find.text('新建一条待办'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '买一束花回家');
    await tester.tap(find.text('生活'));
    await tester.pump();
    await tester.tap(find.text('30 分钟'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final note = controller.all.single;
    expect(note.content, '买一束花回家');
    expect(note.category, TodoCategory.life);
    expect(note.estimateLabel, '30 分钟');
    expect(find.text('买一束花回家'), findsOneWidget);
    expect(find.text('今天要做的\n一件事'), findsOneWidget);
  });

  testWidgets('内容为空时保存按钮点不动，页面不退出', (tester) async {
    final controller = await _pumpApp(tester);
    await _openNewForm(tester);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(controller.all, isEmpty);
    expect(find.text('新建一条待办'), findsOneWidget);
  });

  testWidgets('编辑：点行进入表单，内容预填，保存覆盖后完成时间不变', (tester) async {
    final note = _editableNote();
    final doneNote = note.copyWith(completedAt: DateTime(2026, 10, 30, 10));
    final controller = await _pumpApp(tester, seed: [doneNote]);

    await tester.tap(find.text('旧内容：给琴叶榕换盆'));
    await tester.pumpAndSettle();

    expect(find.text('编辑这条待办'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    // 旧的时间标签会被补成一个可点的档位。
    expect(find.text('1 小时'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '新内容：换一个更大的盆');
    await tester.tap(find.text('生活'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final updated = controller.all.single;
    expect(updated.content, '新内容：换一个更大的盆');
    expect(updated.category, TodoCategory.life);
    expect(updated.estimateLabel, '1 小时');
    expect(updated.completedAt, doneNote.completedAt, reason: '编辑不该改完成时间');
    expect(find.text('新内容：换一个更大的盆'), findsOneWidget);
  });

  testWidgets('删除：确认后移除，提示条可撤销并原样恢复', (tester) async {
    final controller = await _pumpApp(tester, seed: [_editableNote()]);

    await tester.tap(find.text('旧内容：给琴叶榕换盆'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这条待办？'), findsOneWidget);

    // 弹窗里的「删除」是最后一个同名按钮。
    await tester.tap(find.widgetWithText(TextButton, '删除').last);
    await tester.pumpAndSettle();

    expect(controller.all, isEmpty);
    expect(find.text('已删除一条待办'), findsOneWidget);

    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();

    expect(controller.all.single.id, 'edit-1');
    expect(controller.all.single.content, '旧内容：给琴叶榕换盆');
    expect(find.text('旧内容：给琴叶榕换盆'), findsOneWidget);
  });

  testWidgets('取消删除不动数据', (tester) async {
    final controller = await _pumpApp(tester, seed: [_editableNote()]);

    await tester.tap(find.text('旧内容：给琴叶榕换盆'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(controller.all, hasLength(1));
    expect(find.text('编辑这条待办'), findsOneWidget);
  });
}
