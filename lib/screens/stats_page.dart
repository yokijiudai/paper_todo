import 'package:flutter/material.dart';

import '../models/todo_note.dart';
import '../state/todo_controller.dart';
import '../theme/tokens.dart';
import '../utils/formatters.dart';
import '../widgets/day_bar_chart.dart';
import '../widgets/paper_scaffold.dart';
import '../widgets/week_sheet.dart';

/// 回顾页：一周完成多少、每天多少、某天具体做了什么。
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  DateTime? _weekStart;
  int _selected = 0;

  /// 用户手动点过柱子之后，不再自动跳到「完成最多的一天」。
  bool _userPicked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = TodoScope.of(context);
    if (_weekStart == null) {
      final start = mondayOf(controller.now);
      _weekStart = start;
      _selected = _bestIndex(controller.weeklyCounts(start));
      return;
    }
    // 数据在后台变了（完成、删掉、取消勾选）：选中的那天没记录了就换到最多的一天。
    if (!_userPicked) {
      final counts = controller.weeklyCounts(_weekStart!);
      if (counts[_selected] == 0 && counts.any((c) => c > 0)) {
        _selected = _bestIndex(counts);
      }
    }
  }

  /// 完成最多的一天；全为 0 时回周一。
  static int _bestIndex(List<int> counts) {
    var best = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] > counts[best]) best = i;
    }
    return best;
  }

  Future<void> _pickWeek(TodoController controller) async {
    final weekStart = _weekStart!;
    final picked = await showWeekSheet(
      context,
      weekStart: weekStart,
      weekCount: (week) =>
          controller.weeklyCounts(week).fold(0, (a, b) => a + b),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _weekStart = picked;
      _selected = _bestIndex(controller.weeklyCounts(picked));
      _userPicked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = TodoScope.of(context);
    final theme = Theme.of(context);
    final weekStart = _weekStart ?? mondayOf(controller.now);
    final counts = controller.weeklyCounts(weekStart);
    final total = counts.fold(0, (a, b) => a + b);
    final selectedDay = addDays(weekStart, _selected);
    final done = controller.doneOn(selectedDay);
    final streak = controller.streakDays();

    return PaperScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSize.pageX,
          AppSpace.s2,
          AppSize.pageX,
          AppSpace.s5,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  weekKicker(weekStart),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
              _WeekButton(onTap: () => _pickWeek(controller)),
            ],
          ),
          const SizedBox(height: AppSpace.s2),
          Text('这周完成了 $total 件', style: theme.textTheme.displayLarge),
          const SizedBox(height: AppSpace.s4),
          PaperCard(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryStat(value: '$total', unit: '件', label: '完成'),
                ),
                Container(width: 1, height: 48, color: AppColors.line),
                Expanded(
                  child: _SummaryStat(
                    value: '$streak',
                    unit: '天',
                    label: '连续记录',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '每天完成的件数',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      weekRange(weekStart),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s3),
                DayBarChart(
                  counts: counts,
                  selectedIndex: _selected,
                  weekStart: weekStart,
                  onSelect: (index) => setState(() {
                    _selected = index;
                    _userPicked = true;
                  }),
                ),
                const SizedBox(height: AppSpace.s2),
                Text(
                  '点一根柱，看那天做了什么',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.alpha(AppColors.muted, 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${monthDay(selectedDay)} · 周${weekdayShort(selectedDay.weekday)}',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text('${done.length} 件', style: theme.textTheme.bodySmall),
                  ],
                ),
                if (done.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.s2),
                    child: Text(
                      total == 0 ? '这一周还没有完成记录。' : '这天没有完成记录。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < done.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.line,
                      ),
                    _DoneRow(note: done[i]),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部右侧的「换一周」胶囊按钮。
class _WeekButton extends StatelessWidget {
  const _WeekButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: SizedBox(
          height: AppSize.tap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '换一周',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.unit,
    required this.label,
  });

  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

/// 明细里的一行：小勾 + 内容 + 预计花费（没填就显示分类）。
class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.note});

  final TodoNote note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpace.s2),
          Expanded(
            child: Text(
              note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpace.s2),
          Text(
            note.estimateLabel ?? note.category.label,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
