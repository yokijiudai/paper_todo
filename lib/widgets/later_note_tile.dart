import 'package:flutter/material.dart';

import 'package:paper_todo/models/todo_note.dart';
import 'package:paper_todo/theme/tokens.dart';
import 'package:paper_todo/utils/formatters.dart';
import 'package:paper_todo/widgets/category_chip.dart';
import 'package:paper_todo/widgets/check_circle.dart';

/// 「以后」页的一行：一个空勾选圈 + 内容 + 分类和「想到多久以前」+ 右侧「挪到今天」。
///
/// 勾选圈在这里只是「还没做」的记号，不接点击；整行点开编辑页，
/// 右侧那个按钮才是把这件挪回今天清单的动作。
class LaterNoteTile extends StatelessWidget {
  const LaterNoteTile({
    super.key,
    required this.note,
    required this.now,
    this.onTap,
    this.onMoveToToday,
  });

  final TodoNote note;

  /// 用来算「想到 2 天前」，由页面传 controller 的时钟，测试里可固定。
  final DateTime now;

  /// 整行点击（打开编辑页）。
  final VoidCallback? onTap;

  /// 右侧「挪到今天」。
  final VoidCallback? onMoveToToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.md);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 这里不放进完成态：以后的事还没打算今天做。
                  const CheckCircle(checked: false, semanticLabel: '还没安排在今天就做'),
                  const SizedBox(width: 2),
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            CategoryChip(category: note.category),
                            Text(
                              thoughtLabel(note.createdAt, now),
                              maxLines: 1,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _MoveButton(content: note.content, onTap: onMoveToToday),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 44×44 的「挪到今天」，图标是一条顶线加一个向上的箭头。
class _MoveButton extends StatelessWidget {
  const _MoveButton({required this.content, this.onTap});

  final String content;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '把「$content」挪到今天',
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: '挪到今天',
        child: InkResponse(
          onTap: onTap,
          radius: AppSize.tap / 2,
          containedInkWell: true,
          customBorder: const CircleBorder(),
          splashColor: AppColors.primarySoft,
          highlightColor: AppColors.primarySoft,
          child: const SizedBox(
            width: AppSize.tap,
            height: AppSize.tap,
            child: Icon(
              Icons.vertical_align_top_rounded,
              size: 18,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
