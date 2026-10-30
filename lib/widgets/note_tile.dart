import 'package:flutter/material.dart';

import 'package:node/models/todo_note.dart';
import 'package:node/theme/tokens.dart';
import 'package:node/widgets/category_chip.dart';
import 'package:node/widgets/check_circle.dart';

/// 一条待办：左侧勾选圈 + 正文 + 分类与时间。
///
/// 首页两段和回顾页的当日明细都复用这一行；行本身不决定「点一下去哪」，
/// 由 [onTap] 交给调用方。
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, this.onToggle, this.onTap});

  final TodoNote note;

  /// 勾选圈的回调；为 null 时勾选圈不可点。
  final VoidCallback? onToggle;

  /// 整行点击（后续接编辑页）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = note.isCompleted;
    final estimate = note.estimateLabel?.trim() ?? '';
    final hasEstimate = estimate.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CheckCircleSlot(
                    checked: done,
                    onTap: onToggle,
                    content: note.content,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.4,
                            color: done ? AppColors.muted : AppColors.text,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            CategoryChip(category: note.category),
                            if (hasEstimate)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.muted.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    estimate,
                                    maxLines: 1,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.muted,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 勾选圈的适配层：把「标记/取消」的语义文案拼好再交给 [CheckCircle]，
/// 让 [NoteTile] 的布局代码保持干净。
class CheckCircleSlot extends StatelessWidget {
  const CheckCircleSlot({
    super.key,
    required this.checked,
    required this.content,
    this.onTap,
  });

  final bool checked;
  final String content;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CheckCircle(
      checked: checked,
      onTap: onTap,
      semanticLabel: '${checked ? '取消完成' : '标记完成'}：$content',
    );
  }
}
