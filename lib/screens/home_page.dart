import 'package:flutter/material.dart';

import 'package:paper_todo/models/todo_note.dart';
import 'package:paper_todo/state/todo_controller.dart';
import 'package:paper_todo/theme/tokens.dart';
import 'package:paper_todo/utils/formatters.dart';
import 'package:paper_todo/widgets/hero_notes_art.dart';
import 'package:paper_todo/widgets/note_tile.dart';

import 'note_form_page.dart';

/// 今天：上半屏是还没做的，下半屏是已经做完的。
///
/// 页面本身不持有数据，所有统计都从 [TodoController] 的派生属性取，
/// 不在这里判断「今天」「完成」这类业务口径。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TodoScope.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final pending = controller.pending;
    final done = controller.doneToday;
    final total = pending.length + done.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSize.pageX,
        AppSpace.s4,
        AppSize.pageX,
        AppSpace.s5,
      ),
      children: [
        Text(
          dayKicker(now),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _headline(pending.length, total),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displayLarge,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s2),
            const HeroNotesArt(),
          ],
        ),
        const SizedBox(height: AppSpace.s4),
        _ProgressLine(done: done.length, pending: pending.length),
        const SizedBox(height: AppSpace.s5),
        const _SectionHeader('未完成'),
        const SizedBox(height: AppSpace.s3),
        if (pending.isEmpty)
          const _EmptyHint('现在没有待办。', '点下面的 + 写第一条。')
        else
          for (var i = 0; i < pending.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            NoteTile(
              note: pending[i],
              onToggle: () => controller.toggle(pending[i].id),
              onTap: () => _edit(context, pending[i]),
            ),
          ],
        const SizedBox(height: AppSpace.s5),
        const _SectionHeader('今天已完成'),
        const SizedBox(height: AppSpace.s3),
        if (done.isEmpty)
          const _EmptyHint('今天还没有完成的事。', '做完一件，点前面的圈。')
        else
          for (var i = 0; i < done.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            NoteTile(
              note: done[i],
              onToggle: () => controller.toggle(done[i].id),
              onTap: () => _edit(context, done[i]),
            ),
          ],
      ],
    );
  }

  /// 点整行进编辑页；时间标签之类的小改动也不用绕道。
  void _edit(BuildContext context, TodoNote note) {
    Navigator.of(context).pushNamed(NoteFormPage.routeName, arguments: note);
  }

  /// 大标题：没待办时问「想做什么」，全做完时道一声，否则报数。
  String _headline(int pending, int total) {
    if (total == 0) {
      return '今天\n想做什么？';
    }
    if (pending == 0) {
      return '今天的事\n都做完了。';
    }
    return '今天要做的\n${_countLabel(pending)}件事';
  }

  /// 量词前用「两」比「二」顺口；周次之类的序数仍走 [cnNumber]。
  String _countLabel(int n) => n == 2 ? '两' : cnNumber(n);
}

/// 「已完成 X 件 · 还有 Y 件」+ 右侧进度点。
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.done, required this.pending});

  final int done;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final total = done + pending;
    return Row(
      children: [
        Expanded(
          child: Text(
            total == 0 ? '还没有待办' : '已完成 $done 件 · 还有 $pending 件',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
        ),
        if (total > 0) _ProgressDots(done: done, total: total),
      ],
    );
  }
}

/// 最多画 8 个点，超出的部分用「8+」的省略方式表达（原型没有画到那么多）。
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final count = total > 8 ? 8 : total;
    final active = done > 8 ? 8 : done;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < active ? AppColors.accent : AppColors.line,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: AppSpace.s3),
        const Expanded(
          child: Divider(height: 1, thickness: 1, color: AppColors.line),
        ),
      ],
    );
  }
}

/// 没内容时的两行浅话，比空白更像「这个位置本来该有东西」。
class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.first, this.second);

  final String first;
  final String second;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            first,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            second,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.muted.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
