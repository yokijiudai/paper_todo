import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/paper_scaffold.dart';

/// 回顾：统计卡、周柱状图、某天明细、换一周。
///
/// 第一步只搭骨架，等第二步的数据层与第五步的图表组件接上。
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

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
        Text('回顾', style: theme.textTheme.labelSmall),
        const SizedBox(height: AppSpace.s2),
        Text('这一周的\n节奏。', style: theme.textTheme.displayLarge),
        const SizedBox(height: AppSpace.s3),
        Text(
          '柱状图、周历与每天明细在第五步接入。',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpace.s5),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('每天完成的件数', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpace.s2),
              Text('暂无数据', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}