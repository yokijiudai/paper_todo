import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/todo_store.dart';
import '../models/todo_note.dart';
import '../utils/formatters.dart';

/// 待办的全部业务逻辑：增删改查、派生统计、持久化调度。
///
/// 页面只读这里的数据、只调这里的方法，不自己算「今天完成几件」。
/// 写操作先改内存并广播，再 250ms 防抖落盘，避免连点勾选时反复写盘。
class TodoController extends ChangeNotifier {
  TodoController(
    this._store, {
    this.saveDebounce = const Duration(milliseconds: 250),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final TodoStore _store;

  /// 落盘防抖窗口，测试里调小。
  final Duration saveDebounce;

  /// 取「现在」的时钟，测试里注入固定时间。
  final DateTime Function() _now;

  final List<TodoNote> _notes = [];
  Timer? _saveTimer;
  bool _dirty = false;
  bool _isLoading = true;
  Object? _error;

  bool get isLoading => _isLoading;

  /// 上次 [load] 的错误；读失败时列表为空，页面按空数据处理。
  Object? get error => _error;

  /// 全部待办，按创建时间倒序（最新的在最前）。
  List<TodoNote> get all => List.unmodifiable(_notes);

  /// 未完成，创建时间倒序。
  List<TodoNote> get pending =>
      _notes.where((n) => !n.isCompleted).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// 今天完成，完成时间倒序。
  List<TodoNote> get doneToday => doneOn(_now());

  /// 首页进度点：「未完成 + 今天已完成」。
  int get todayTotal => pending.length + doneToday.length;

  /// 指定某天完成的所有待办，完成时间倒序。
  List<TodoNote> doneOn(DateTime day) {
    final result = _notes.where((n) {
      final completedAt = n.completedAt;
      return completedAt != null && isSameDay(completedAt, day);
    }).toList();
    result.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    return result;
  }

  /// 从 [weekStart]（应为周一）起 7 天的完成件数，给柱状图。
  List<int> weeklyCounts(DateTime weekStart) {
    final start = mondayOf(weekStart);
    return List.generate(7, (i) => doneOn(addDays(start, i)).length);
  }

  /// 连续完成天数。
  ///
  /// 从今天往回数「当天至少完成 1 件」的连续天数；今天还没完成时从昨天起算，
  /// 当天没结束不算断。最多回望一年，避免脏数据死循环。
  int streakDays([DateTime? today]) {
    var day = dateOnly(today ?? _now());
    if (doneOn(day).isEmpty) day = addDays(day, -1);
    var count = 0;
    while (count < 366 && doneOn(day).isNotEmpty) {
      count++;
      day = addDays(day, -1);
    }
    return count;
  }

  /// 冷启动时读存储；失败只记 [error]，不把异常抛给 UI。
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final loaded = await _store.load();
      _notes
        ..clear()
        ..addAll(loaded);
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 新建一条，插到最前面（创建时间最新）。
  ///
  /// 内容为空抛 [ArgumentError]，由页面先拦一道。
  Future<TodoNote> add({
    required String content,
    TodoCategory category = TodoCategory.work,
    String? timeLabel,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(content, 'content', '内容不能为空');
    }
    final note = TodoNote(
      id: _newId(),
      content: trimmed,
      category: category,
      timeLabel: timeLabel,
      createdAt: _now(),
    );
    _notes.insert(0, note);
    notifyListeners();
    _persist();
    return note;
  }

  /// 整体替换一条（编辑页把改好的 note 传回来）。
  Future<void> update(TodoNote note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index < 0) return;
    _notes[index] = note;
    notifyListeners();
    _persist();
  }

  /// 勾选 / 取消勾选。
  Future<void> toggle(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index < 0) return;
    final note = _notes[index];
    final wasCompleted = note.isCompleted;
    _notes[index] = note.copyWith(
      completedAt: wasCompleted ? null : _now(),
      clearCompletedAt: wasCompleted,
    );
    notifyListeners();
    _persist();
  }

  Future<void> remove(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index < 0) return;
    _notes.removeAt(index);
    notifyListeners();
    _persist();
  }

  /// 撤销删除：把原来的便签放回列表，保留 id、创建时间和完成时间。
  ///
  /// 只在删除提示条的「撤销」里用。已在列表里（比如撤销后又删了）就忽略。
  void restore(TodoNote note) {
    if (_notes.any((n) => n.id == note.id)) return;
    _notes.add(note);
    notifyListeners();
    _persist();
  }

  /// 立即落盘（跳过防抖）。页面退出、应用进后台时调一下，保证最后一下改动不丢。
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_dirty) return;
    _dirty = false;
    await _store.save(List.of(_notes));
  }

  void _persist() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDebounce, () {
      _saveTimer = null;
      if (!_dirty) return;
      _dirty = false;
      unawaited(
        _store.save(List.of(_notes)).catchError((Object e, StackTrace s) {
          debugPrint('TodoStore.save 失败: $e\n$s');
        }),
      );
    });
  }

  String _newId() => _now().microsecondsSinceEpoch.toRadixString(36);

  @override
  void dispose() {
    _saveTimer?.cancel();
    // 防抖窗口内退出：尽力把这批改动写下去，不等结果。
    if (_dirty) {
      _dirty = false;
      unawaited(_store.save(List.of(_notes)).catchError((_) {}));
    }
    super.dispose();
  }
}

/// 把 controller 放进 widget 树。
///
/// 只提供实例本身：[TodoScope.of] 返回 controller，页面用
/// `AnimatedBuilder(animation: controller, ...)` 订阅变化。
class TodoScope extends InheritedNotifier<TodoController> {
  const TodoScope({
    super.key,
    required TodoController controller,
    required super.child,
  }) : super(notifier: controller);

  static TodoController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TodoScope>();
    assert(
      scope != null,
      'TodoScope 未挂载：请在 MaterialApp 的 child 外面包一层 TodoScope',
    );
    return scope!.notifier!;
  }

  /// 允许缺席（预览、局部测试时返回 null）。
  static TodoController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TodoScope>()?.notifier;
}
