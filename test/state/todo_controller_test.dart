import 'package:flutter_test/flutter_test.dart';
import 'package:paper_todo/data/todo_store.dart';
import 'package:paper_todo/models/todo_note.dart';
import 'package:paper_todo/state/todo_controller.dart';

/// load 直接抛错的存储，用来验证 controller 不把异常抛给 UI。
class _FailingStore implements TodoStore {
  @override
  Future<List<TodoNote>> load() async => throw StateError('磁盘坏了');

  @override
  Future<void> save(List<TodoNote> notes) async {}
}

void main() {
  // 固定「现在」：2026-10-30 周五 09:00，让派生统计可断言。
  late DateTime current;
  late MemoryTodoStore store;
  late TodoController controller;
  var seq = 0;

  TodoNote makeNote({
    DateTime? createdAt,
    DateTime? completedAt,
    String content = '一件事',
    TodoCategory category = TodoCategory.work,
    String? estimateLabel,
  }) => TodoNote(
    id: 'seed${seq++}',
    content: content,
    category: category,
    estimateLabel: estimateLabel,
    createdAt: createdAt ?? DateTime(2026, 10, 25, 8),
    completedAt: completedAt,
  );

  setUp(() {
    current = DateTime(2026, 10, 30, 9);
    store = MemoryTodoStore();
    controller = TodoController(
      store,
      now: () => current,
      saveDebounce: const Duration(milliseconds: 10),
    );
  });

  TodoController controllerWith(List<TodoNote> seed) => TodoController(
    MemoryTodoStore(seed),
    now: () => current,
    saveDebounce: const Duration(milliseconds: 10),
  );

  group('增删改查', () {
    test('add 插到最前、去掉首尾空格，并写盘', () async {
      final a = await controller.add(
        content: '  写 Q4 提案提纲  ',
        category: TodoCategory.study,
        estimateLabel: '1 小时',
      );
      current = current.add(const Duration(minutes: 1));
      final b = await controller.add(
        content: '给琴叶榕换盆',
        category: TodoCategory.life,
      );

      expect(a.content, '写 Q4 提案提纲');
      expect(a.category, TodoCategory.study);
      expect(a.estimateLabel, '1 小时');
      expect(controller.pending.map((n) => n.id), [b.id, a.id]);
      expect(controller.todayTotal, 2);

      await controller.flush();
      expect(store.notes.map((n) => n.id), [b.id, a.id]);
    });

    test('add 空内容抛 ArgumentError', () async {
      await expectLater(controller.add(content: '   '), throwsArgumentError);
      expect(controller.all, isEmpty);
    });

    test('toggle 完成：从未完成进今天完成，写入 completedAt', () async {
      final note = await controller.add(content: '读一章书');
      await controller.toggle(note.id);

      expect(controller.pending, isEmpty);
      expect(controller.doneToday.single.id, note.id);
      expect(controller.doneToday.single.completedAt, current);
      expect(controller.todayTotal, 1);

      await controller.flush();
      expect(store.notes.single.completedAt, current);
    });

    test('再 toggle 一次撤销完成状态', () async {
      final note = await controller.add(content: '读一章书');
      await controller.toggle(note.id);
      await controller.toggle(note.id);

      expect(controller.doneToday, isEmpty);
      expect(controller.pending.single.isCompleted, isFalse);

      await controller.flush();
      expect(store.notes.single.completedAt, isNull);
    });

    test('update 整体替换内容、分类、时间文案', () async {
      final note = await controller.add(content: '草稿');
      await controller.update(
        note.copyWith(
          content: '终稿',
          category: TodoCategory.idea,
          estimateLabel: '2 小时',
        ),
      );

      final updated = controller.all.single;
      expect(updated.content, '终稿');
      expect(updated.category, TodoCategory.idea);
      expect(updated.estimateLabel, '2 小时');
      expect(updated.createdAt, note.createdAt);
    });

    test('remove 删掉指定 id，未知 id 不报错', () async {
      final note = await controller.add(content: '要删的');
      await controller.remove('不存在的 id');
      expect(controller.all, hasLength(1));

      await controller.remove(note.id);
      expect(controller.all, isEmpty);
    });

    test('restore 把删掉的便签原样放回，重复放回不叠加', () async {
      final note = await controller.add(content: '寄一张明信片');
      await controller.remove(note.id);
      expect(controller.all, isEmpty);

      controller.restore(note);
      expect(controller.all.single.id, note.id);
      expect(controller.all.single.createdAt, note.createdAt);
      expect(controller.all.single.content, '寄一张明信片');

      controller.restore(note);
      expect(controller.all, hasLength(1));
    });
  });

  group('派生统计', () {
    test('doneOn 按天过滤，weeklyCounts 给出 7 天件数', () async {
      final c = controllerWith([
        makeNote(completedAt: DateTime(2026, 10, 30, 8)), // 周五
        makeNote(completedAt: DateTime(2026, 10, 29, 21)), // 周四
        makeNote(completedAt: DateTime(2026, 10, 27, 7)), // 周二
        makeNote(completedAt: DateTime(2026, 10, 20, 7)), // 上周二
        makeNote(), // 未完成
      ]);
      await c.load();

      expect(c.doneOn(DateTime(2026, 10, 30)), hasLength(1));
      expect(c.weeklyCounts(DateTime(2026, 10, 26)), [0, 1, 0, 1, 1, 0, 0]);
      expect(c.todayTotal, 1 + 1); // 1 未完成 + 1 今天完成
    });

    test('streakDays 数连续天数，中断即停', () async {
      final c = controllerWith([
        makeNote(completedAt: DateTime(2026, 10, 30, 8)),
        makeNote(completedAt: DateTime(2026, 10, 29, 8)),
        makeNote(completedAt: DateTime(2026, 10, 27, 8)), // 28 号空 → 断
      ]);
      await c.load();

      expect(c.streakDays(), 2);
      expect(c.streakDays(DateTime(2026, 10, 27)), 1);
    });

    test('今天还没完成时，从昨天起算（当天未结束不算断）', () async {
      final c = controllerWith([
        makeNote(completedAt: DateTime(2026, 10, 29, 8)),
      ]);
      await c.load();
      expect(c.streakDays(), 1);
    });

    test('一条完成都没有时连续天数为 0', () async {
      final c = controllerWith([makeNote()]);
      await c.load();
      expect(c.streakDays(), 0);
    });
  });

  group('加载与落盘', () {
    test('load 读存储、结束加载态', () async {
      final c = controllerWith([
        makeNote(completedAt: DateTime(2026, 10, 30, 8)),
      ]);
      expect(c.isLoading, isTrue);
      await c.load();

      expect(c.isLoading, isFalse);
      expect(c.error, isNull);
      expect(c.doneToday, hasLength(1));
    });

    test('load 失败只记录 error，不抛异常', () async {
      final c = TodoController(_FailingStore(), now: () => current);
      await c.load();

      expect(c.error, isA<StateError>());
      expect(c.all, isEmpty);
      expect(c.isLoading, isFalse);
    });

    test('连点只写一次盘（250ms 防抖）', () async {
      await controller.add(content: 'a');
      await controller.add(content: 'b');
      await controller.add(content: 'c');

      expect(store.saveCount, 0);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(store.saveCount, 1);
      expect(store.notes, hasLength(3));
    });

    test('flush 跳过防抖立即落盘', () async {
      await controller.add(content: 'a');
      expect(store.saveCount, 0);
      await controller.flush();
      expect(store.saveCount, 1);
      expect(store.notes, hasLength(1));
    });
  });
}
