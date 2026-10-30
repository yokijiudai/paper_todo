import 'package:flutter/foundation.dart';

/// 待办分类。存 `name`（`work/life/study/idea`），不存下标。
enum TodoCategory {
  work('工作'),
  life('生活'),
  study('学习'),
  idea('灵感');

  const TodoCategory(this.label);

  /// 展示用中文名。
  final String label;

  /// 从 JSON 里的字符串还原；未知值回落 [work]，不丢数据。
  static TodoCategory fromName(Object? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => work);
}

/// 一条待办。
///
/// 不可变：任何修改都走 [copyWith] 或 controller，页面不直接赋值。
/// 完成状态只由 [completedAt] 决定，`null` 即未完成。
@immutable
class TodoNote {
  const TodoNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.category = TodoCategory.work,
    this.estimateLabel,
    this.completedAt,
  });

  final String id;
  final String content;
  final TodoCategory category;

  /// 预计花费的时间文案（"15 分钟" / "1 小时" / "半天"），只展示、不解析。
  ///
  /// 前身是「几点做」（"14:00" / "傍晚"），旧数据仍能从 `timeLabel` 读进来。
  final String? estimateLabel;
  final DateTime createdAt;

  /// 完成时间；`null` 表示未完成。
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  /// 复制并修改字段。
  ///
  /// [completedAt] 传 `null` 表示「不修改」；要显式撤销完成状态，
  /// 传 [clearCompletedAt] = true，避免和「不改」混淆。
  TodoNote copyWith({
    String? content,
    TodoCategory? category,
    String? estimateLabel,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    assert(
      !(clearCompletedAt && completedAt != null),
      'completedAt 与 clearCompletedAt 不能同时给',
    );
    return TodoNote(
      id: id,
      content: content ?? this.content,
      createdAt: createdAt,
      category: category ?? this.category,
      estimateLabel: estimateLabel ?? this.estimateLabel,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'content': content,
    'category': category.name,
    'estimate': estimateLabel,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  /// 解析失败（content 缺失）抛 [FormatException]，由存储层跳过这一条。
  factory TodoNote.fromJson(Map<String, Object?> json) {
    final content = json['content'];
    if (content is! String) {
      throw const FormatException('TodoNote.content 缺失或不是字符串');
    }
    return TodoNote(
      id: json['id'] as String? ?? '',
      content: content,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      category: TodoCategory.fromName(json['category']),
      // 旧版本把「预计花费」存成 timeLabel（当时含义是几点做），读的时候兼容一下。
      estimateLabel: (json['estimate'] ?? json['timeLabel']) as String?,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }

  @override
  String toString() =>
      'TodoNote($id, ${category.name}, $content'
      '${isCompleted ? ', completedAt: $completedAt' : ''})';
}
