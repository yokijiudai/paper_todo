import 'package:paper_todo/models/todo_note.dart';

/// 首次启动是否写入示例数据。
///
/// 这是个演示用途的开关：真机上第一次打开就能看到「纸感」效果，
/// 而不是四屏皆空。发版或用户不想要示例时改成 `false` 即可。
const bool kSeedDemoOnFirstRun = true;

/// 原型里的示例：首页五条，「以后」页再放几条不着急的。
///
/// 日期取「今天」，保证一打开就有未完成、今天已完成、以后三段内容。
/// id 固定，重复写入不会产生重复条目。
List<TodoNote> demoNotes({DateTime? now}) {
  final base = now ?? DateTime.now();
  final today = DateTime(base.year, base.month, base.day);
  // 首页按 placedAt 排队。示例的创建时间固定写成上午，清晨启动时会比「现在」还晚，
  // 所以额外把 placedAt 设成启动前几分钟，保证新挪过来的事能排在最上面。
  DateTime placedAgo(int minutes) => base.subtract(Duration(minutes: minutes));

  return [
    // 未完成：按放进今天的时间倒序，例会最近 → 排最前，与原型顺序一致。
    TodoNote(
      id: 'seed-meeting',
      content: '团队例会',
      category: TodoCategory.work,
      estimateLabel: '1 小时',
      createdAt: today.add(const Duration(hours: 9, minutes: 20)),
      placedAt: placedAgo(5),
    ),
    TodoNote(
      id: 'seed-pr',
      content: '审阅新功能分支的 PR',
      category: TodoCategory.work,
      estimateLabel: '30 分钟',
      createdAt: today.add(const Duration(hours: 9, minutes: 5)),
      placedAt: placedAgo(10),
    ),
    TodoNote(
      id: 'seed-plant',
      content: '给阳台的琴叶榕换盆',
      category: TodoCategory.life,
      estimateLabel: '30 分钟',
      createdAt: today.add(const Duration(hours: 8, minutes: 40)),
      placedAt: placedAgo(20),
    ),
    // 今天已完成：按完成时间倒序，提案在读书之后完成 → 排更前。
    TodoNote(
      id: 'seed-proposal',
      content: '写完 Q4 项目提案的提纲',
      category: TodoCategory.work,
      estimateLabel: '1 小时',
      createdAt: today.add(const Duration(hours: 8)),
      completedAt: today.add(const Duration(hours: 10, minutes: 30)),
    ),
    TodoNote(
      id: 'seed-book',
      content: '读完《写作这回事》第 4 章',
      category: TodoCategory.study,
      estimateLabel: '30 分钟',
      createdAt: today.add(const Duration(hours: 8, minutes: 10)),
      completedAt: today.add(const Duration(hours: 9, minutes: 15)),
    ),
    // 以后：不安排在今天的几件，创建时间故意错开，让「想到 X 天前」有层次。
    _someday('seed-coffee', '学做一次手冲咖啡', TodoCategory.life, today, 2),
    _someday('seed-wall', '把阳台那面墙刷成米色', TodoCategory.life, today, 5),
    _someday('seed-sapiens', '读完《人类简史》', TodoCategory.study, today, 7),
    _someday('seed-call', '给爸妈打个长电话', TodoCategory.life, today, 3),
    _someday('seed-tool', '试试用 Flutter 写个小工具', TodoCategory.work, today, 1),
  ];
}

/// 「以后」里的示例：创建于 [daysAgo] 天前的傍晚。
TodoNote _someday(
  String id,
  String content,
  TodoCategory category,
  DateTime today,
  int daysAgo,
) {
  final createdAt = today
      .subtract(Duration(days: daysAgo))
      .add(const Duration(hours: 19));
  return TodoNote(
    id: id,
    content: content,
    category: category,
    createdAt: createdAt,
    bucket: TodoBucket.later,
  );
}
