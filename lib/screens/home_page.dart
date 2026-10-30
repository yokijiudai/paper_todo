import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/paper_scaffold.dart';

/// 今天：标题、进度、未完成、今天已完成。
///
/// 第一步只搭骨架：纸底、字号层级、卡片与留白先落位，数据在第二步接入后替换占位内容。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSize.pageX,
        AppSpace.s2,
        AppSize.pageX,
        AppSpace.s6,
      ),
      children: [
        Text('今天', style: theme.textTheme.labelSmall),
        const SizedBox(height: AppSpace.s2),
        Text('先把今天\n写下来。', style: theme.textTheme.displayLarge),
        const SizedBox(height: AppSpace.s3),
        Text(
          '骨架已就绪：纸底、主题变量、标签栏。\n数据层与待办列表在下一步接入。',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpace.s5),
        const PaperCard(
          child: Column(
            children: [
              _DoneRow('设计变量', 'theme/tokens.dart'),
              SizedBox(height: AppSpace.s3),
              _DoneRow('纸面与卡片', 'widgets/paper_scaffold.dart'),
              SizedBox(height: AppSpace.s3),
              _DoneRow('标签栏', 'widgets/diy_tabbar.dart'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow(this.label, this.detail);

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.accent,
        ),
        const SizedBox(width: AppSpace.s3),
        Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
        Text(detail, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
