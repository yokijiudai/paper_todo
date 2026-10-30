import 'package:paper_todo/models/todo_note.dart';

/// 首次启动是否写入示例数据。
///
/// 这是个演示用途的开关：真机上第一次打开就能看到「纸感」效果，
/// 而不是四屏皆空。发版或用户不想要示例时改成 `false` 即可。
const bool kSeedDemoOnFirstRun = true;

/// 原型首页的那五条示例，日期取「今天」，保证一打开就有未完成与已完成两段。
///
/// id 固定，重复写入不会产生重复条目。
List<TodoNote> demoNotes({DateTime? now}) {
  final base = now ?? DateTime.now();
  final today = DateTime(base.year, base.month, base.day);
  return [
    // 未完成：按创建时间倒序，例会最新 → 排最前，与原型顺序一致。
    TodoNote(
      id: 'seed-meeting',
      content: '团队例会',
      category: TodoCategory.work,
      estimateLabel: '1 小时',
      createdAt: today.add(const Duration(hours: 9, minutes: 20)),
    ),
    TodoNote(
      id: 'seed-pr',
      content: '审阅新功能分支的 PR',
      category: TodoCategory.work,
      estimateLabel: '30 分钟',
      createdAt: today.add(const Duration(hours: 9, minutes: 5)),
    ),
    TodoNote(
      id: 'seed-plant',
      content: '给阳台的琴叶榕换盆',
      category: TodoCategory.life,
      estimateLabel: '30 分钟',
      createdAt: today.add(const Duration(hours: 8, minutes: 40)),
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
  ];
}
