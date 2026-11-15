import 'package:flutter/material.dart';

import 'package:paper_todo/theme/tokens.dart';

/// 主操作按钮：52 高、主色实底、暖褐投影。
///
/// [onPressed] 为 null 时变浅且点不动，用来表达「内容还没写」。
/// 投影用手写 BoxShadow 而不是 Material 的 elevation —— 后者在浅色底上会晕成
/// 一圈光环，和纸感的「软投影」不是一回事。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  /// 与原型 `.btn-primary` 的 `0 8px 20px rgba(120, 72, 30, .18)` 一致。
  static const _shadow = <BoxShadow>[
    BoxShadow(color: Color(0x2E784820), blurRadius: 20, offset: Offset(0, 8)),
  ];

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(AppRadius.md);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: enabled ? _shadow : const <BoxShadow>[],
        ),
        child: Material(
          color: enabled
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.34),
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppText.md,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.primaryInk
                      : AppColors.primaryInk.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
