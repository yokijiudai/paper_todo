import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:paper_todo/theme/tokens.dart';

/// 手绘感的完成勾选：外圈线条 + 实心填充 + 一笔画出的勾。
///
/// 命中区固定 44×44（比 24 的视觉尺寸大一圈），由 [AppSize.tap] 决定；
/// 勾的描边用 `PathMetrics` 做「画出来」的过渡，时长跟随系统减弱动效设置。
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    super.key,
    required this.checked,
    this.onTap,
    this.size = AppSize.check,
    this.semanticLabel,
  });

  /// 是否完成。
  final bool checked;

  /// 点击回调；为 null 时不可点。
  final VoidCallback? onTap;

  /// 圆的视觉直径，默认 [AppSize.check]（24）。
  final double size;

  /// 无障碍朗读文案，默认根据 [checked] 生成。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = AppMotion.scaled(
      context,
      reduceMotion ? Duration.zero : AppMotion.fast,
    );
    final label = semanticLabel ?? (checked ? '标记为未完成' : '标记为已完成');

    return Semantics(
      button: onTap != null,
      checked: checked,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: AppSize.tap / 2,
        containedInkWell: false,
        highlightShape: BoxShape.circle,
        child: SizedBox(
          width: AppSize.tap,
          height: AppSize.tap,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: checked ? 1 : 0),
              duration: duration,
              curve: AppMotion.ease,
              builder: (context, progress, _) {
                return CustomPaint(
                  size: Size.square(size),
                  painter: _CheckPainter(progress: progress),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress});

  /// 0 = 未完成，1 = 完成，中间值是动画过程。
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 描边圆圈：未完成时是细线，完成过程中逐渐被主色填充压过去。
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Color.lerp(
        AppColors.muted.withValues(alpha: 0.7),
        AppColors.accent,
        progress,
      )!;
    canvas.drawCircle(rect.center, size.width / 2 - 1, border);

    if (progress > 0) {
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.accent.withValues(alpha: progress);
      canvas.drawCircle(rect.center, size.width / 2 - 1, fill);

      // 勾：三点折线，末段略提笔，像手写的一笔。
      final metricPath = Path()
        ..moveTo(size.width * 0.27, size.height * 0.52)
        ..quadraticBezierTo(
          size.width * 0.36,
          size.height * 0.63,
          size.width * 0.45,
          size.height * 0.71,
        )
        ..lineTo(size.width * 0.74, size.height * 0.33);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.primaryInk.withValues(alpha: progress);

      for (final metric in metricPath.computeMetrics()) {
        final length = metric.length;
        if (length <= 0) {
          continue;
        }
        final visible = math.min(progress * 1.08, 1.0);
        canvas.drawPath(metric.extractPath(0, length * visible), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
