import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:node/data/todo_store.dart';
import 'package:node/models/todo_note.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    // 用官方提供的内存版平台实现，单测里不需要真机通道。
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  final note = TodoNote(
    id: 'm3k9x2a1',
    content: '周五前把提案终稿发给 Amanda',
    category: TodoCategory.study,
    timeLabel: '傍晚',
    createdAt: DateTime(2026, 10, 30, 9, 12),
    completedAt: DateTime(2026, 10, 30, 10, 30),
  );

  test('save 后 load 原样读回全部字段', () async {
    final store = SharedPrefsTodoStore();
    await store.save([note]);

    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, note.id);
    expect(loaded.single.content, note.content);
    expect(loaded.single.category, TodoCategory.study);
    expect(loaded.single.timeLabel, '傍晚');
    expect(loaded.single.createdAt, note.createdAt);
    expect(loaded.single.completedAt, note.completedAt);
  });

  test('空存储返回空列表', () async {
    expect(await SharedPrefsTodoStore().load(), isEmpty);
  });

  test('重复 save 是覆盖而不是追加', () async {
    final store = SharedPrefsTodoStore();
    await store.save([note]);
    await store.save([note, note.copyWith(content: '第二条', completedAt: null)]);

    expect((await store.load()), hasLength(2));
  });

  test('坏 JSON 返回空列表且不抛异常', () async {
    await SharedPreferencesAsync().setString(
      SharedPrefsTodoStore.key,
      '{not json',
    );

    expect(await SharedPrefsTodoStore().load(), isEmpty);
  });

  test('单条坏数据被跳过，其余正常读回', () async {
    await SharedPreferencesAsync().setString(
      SharedPrefsTodoStore.key,
      jsonEncode({
        'version': 1,
        'notes': [
          {
            'id': 'ok',
            'content': '正常的一条',
            'createdAt': '2026-10-30T09:00:00.000',
          },
          {'id': 'bad'}, // 缺 content
        ],
      }),
    );

    final loaded = await SharedPrefsTodoStore().load();
    expect(loaded.single.id, 'ok');
  });

  test('MemoryTodoStore 记录 save 次数，供防抖断言', () async {
    final store = MemoryTodoStore([note]);
    await store.load();
    await store.save([note]);
    await store.save([]);

    expect(store.saveCount, 2);
    expect(store.notes, isEmpty);
  });
}
