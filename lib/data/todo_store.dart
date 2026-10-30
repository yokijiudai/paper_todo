import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo_note.dart';

/// 待办列表的读写接口。
///
/// 换存储（sqflite / 云同步）只需新增一个实现，`main.dart` 换一行。
abstract interface class TodoStore {
  Future<List<TodoNote>> load();
  Future<void> save(List<TodoNote> notes);
}

/// 把整份列表序列化成一段 JSON，存进 SharedPreferences 的单个 key。
///
/// 用 2.5 的 [SharedPreferencesAsync]：读写直接落到平台侧，没有进程内缓存，
/// 比旧的 `SharedPreferences.getInstance()` 少一层缓存不一致的坑。
class SharedPrefsTodoStore implements TodoStore {
  SharedPrefsTodoStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  /// key 带版本号：结构要改时写 `todo.notes.v2`，v1 留作迁移来源。
  static const String key = 'todo.notes.v1';

  final SharedPreferencesAsync _prefs;

  @override
  Future<List<TodoNote>> load() async {
    try {
      final raw = await _prefs.getString(key);
      if (raw == null || raw.isEmpty) return const <TodoNote>[];
      final payload = jsonDecode(raw);
      if (payload is! Map<String, Object?>) return const <TodoNote>[];
      final rawNotes = payload['notes'];
      if (rawNotes is! List) return const <TodoNote>[];

      final notes = <TodoNote>[];
      for (final item in rawNotes) {
        if (item is! Map<String, Object?>) continue;
        try {
          notes.add(TodoNote.fromJson(item));
        } catch (e) {
          // 单条坏数据只丢这一条，不能让整份列表读不出来。
          debugPrint('SharedPrefsTodoStore: 跳过坏数据 $e');
        }
      }
      return notes;
    } catch (e, stack) {
      // 坏数据最多丢一次，不能把异常抛给 UI 造成白屏。
      debugPrint('SharedPrefsTodoStore.load 失败: $e\n$stack');
      return const <TodoNote>[];
    }
  }

  @override
  Future<void> save(List<TodoNote> notes) async {
    final payload = <String, Object?>{
      'version': 1,
      'notes': notes.map((n) => n.toJson()).toList(),
    };
    await _prefs.setString(key, jsonEncode(payload));
  }
}

/// 内存实现：单测和 UI 预览用，进程结束数据就没了。
class MemoryTodoStore implements TodoStore {
  MemoryTodoStore([Iterable<TodoNote>? initial]) : _notes = [...?initial];

  List<TodoNote> _notes;
  int _saveCount = 0;

  /// 当前存着的列表（只读快照）。
  List<TodoNote> get notes => List.unmodifiable(_notes);

  /// 被调用过多少次 [save]，用来验证防抖。
  int get saveCount => _saveCount;

  @override
  Future<List<TodoNote>> load() async => List.of(_notes);

  @override
  Future<void> save(List<TodoNote> notes) async {
    _notes = List.of(notes);
    _saveCount++;
  }
}
