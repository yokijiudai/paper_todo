import 'package:flutter_test/flutter_test.dart';
import 'package:node/models/todo_note.dart';

void main() {
  final createdAt = DateTime(2026, 10, 30, 9, 12);
  final completedAt = DateTime(2026, 10, 30, 10, 30);

  TodoNote makeNote({
    DateTime? completed,
    TodoCategory category = TodoCategory.work,
  }) => TodoNote(
    id: 'm3k9x2a1',
    content: '写完 Q4 提案的提纲',
    category: category,
    estimateLabel: '30 分钟',
    createdAt: createdAt,
    completedAt: completed,
  );

  group('TodoNote', () {
    test('toJson / fromJson 往返保留全部字段', () {
      final note = makeNote(
        completed: completedAt,
        category: TodoCategory.study,
      );
      final back = TodoNote.fromJson(note.toJson());

      expect(back.id, note.id);
      expect(back.content, note.content);
      expect(back.category, TodoCategory.study);
      expect(back.estimateLabel, '30 分钟');
      expect(back.createdAt, createdAt);
      expect(back.completedAt, completedAt);
    });

    test('isCompleted 只由 completedAt 决定', () {
      expect(makeNote().isCompleted, isFalse);
      expect(makeNote(completed: completedAt).isCompleted, isTrue);
    });

    test('未知 category 回落 work，不丢数据', () {
      final json = makeNote().toJson()..['category'] = 'unknown';
      expect(TodoNote.fromJson(json).category, TodoCategory.work);
    });

    test('createdAt 坏了用当前时间兜底，正文仍可读', () {
      final json = makeNote().toJson()..['createdAt'] = 'not-a-date';
      final note = TodoNote.fromJson(json);
      expect(note.content, '写完 Q4 提案的提纲');
      expect(note.createdAt, isA<DateTime>());
    });

    test('copyWith 默认保留完成时间，clearCompletedAt 才能撤销', () {
      final done = makeNote(completed: completedAt);
      expect(done.copyWith(content: '改个标题').completedAt, completedAt);

      final undone = done.copyWith(clearCompletedAt: true);
      expect(undone.completedAt, isNull);
      expect(undone.isCompleted, isFalse);
      expect(undone.content, done.content);
    });

    test('toJson 用新键 estimate，旧的 timeLabel 仍能读', () {
      final note = makeNote();
      expect(note.toJson()['estimate'], '30 分钟');
      expect(note.toJson().containsKey('timeLabel'), isFalse);

      final legacy = note.toJson()
        ..remove('estimate')
        ..['timeLabel'] = '14:00';
      expect(TodoNote.fromJson(legacy).estimateLabel, '14:00');
    });

    test('缺 content 抛 FormatException（由存储层跳过这一条）', () {
      expect(
        () => TodoNote.fromJson({
          'id': 'x',
          'createdAt': '2026-10-30T09:00:00.000',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
