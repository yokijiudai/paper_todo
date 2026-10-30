import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/paper_scaffold.dart';

/// 新建 / 编辑待办（同一页，传 note 即编辑）。
///
/// 第四步接入真正的表单；这一步只把页面结构与底部保存栏搭出来。
class NoteFormPage extends StatelessWidget {
  const NoteFormPage({super.key});

  static const routeName = '/note';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PaperScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: '关闭',
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSize.pageX,
                0,
                AppSize.pageX,
                AppSpace.s6,
              ),
              children: [
                Text('新建', style: theme.textTheme.labelSmall),
                const SizedBox(height: AppSpace.s2),
                Text('写一条待办', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpace.s2),
                Text(
                  '写下来就行，不用想得太完整。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpace.s5),
                Container(
                  constraints: const BoxConstraints(minHeight: 184),
                  padding: const EdgeInsets.all(AppSpace.s4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    '输入框（第四步接入）',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomBar: const _FormActionBar(),
    );
  }
}

class _FormActionBar extends StatelessWidget {
  const _FormActionBar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.up,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSize.pageX,
            AppSpace.s3,
            AppSize.pageX,
            AppSpace.s3,
          ),
          child: SizedBox(
            height: 52,
            child: Material(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: const Center(
                child: Text(
                  '保存',
                  style: TextStyle(
                    fontSize: AppText.md,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}