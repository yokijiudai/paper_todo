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

/// 待办所在的栏位：今天要做的，还是先放着。
///
/// 「以后」不是完成状态，只是暂时不安排在今天的清单；挪到今天仍是一条未完成待办。
enum TodoBucket {
  today('今天'),
  later('以后');

  const TodoBucket(this.label);

  /// 展示用中文名。
  final String label;

  /// 从 JSON 还原；旧数据没有这个字段，一律算「今天」，不会把已有待办藏起来。
  static TodoBucket fromName(Object? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => today);
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
    this.bucket = TodoBucket.today,
    this.placedAt,
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

  /// 这条待在「今天」还是「以后」。
  final TodoBucket bucket;

  /// 进入当前栏位的时间：新建、从「以后」挪到今天时写入。
  ///
  /// 「以后」页按 [createdAt] 排序（想到得越晚越靠上），「今天」页按这个排，
  /// 刚挪过来的事因此会出现在最前面。旧数据没有这个字段，回落到 [createdAt]。
  final DateTime? placedAt;

  bool get isCompleted => completedAt != null;

  /// 排序用的「放进本栏时间」。
  DateTime get placedOn => placedAt ?? createdAt;

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
    TodoBucket? bucket,
    DateTime? placedAt,
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
      bucket: bucket ?? this.bucket,
      placedAt: placedAt ?? this.placedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'content': content,
    'category': category.name,
    'estimate': estimateLabel,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'bucket': bucket.name,
    'placedAt': placedAt?.toIso8601String(),
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
      // 没有 bucket 的老数据算「今天」，不会被新加的「以后」页藏掉。
      bucket: TodoBucket.fromName(json['bucket']),
      placedAt: DateTime.tryParse(json['placedAt'] as String? ?? ''),
    );
  }

  @override
  String toString() =>
      'TodoNote($id, ${category.name}, ${bucket.name}, $content'
      '${isCompleted ? ', completedAt: $completedAt' : ''})';
}
