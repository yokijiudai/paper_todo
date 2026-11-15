import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:paper_todo/theme/tokens.dart';

/// 「以后」页标题右侧的纸飞机：一条虚线航线 + 两片折纸。
///
/// 照原型 `later.html` 里的 SVG 用 [CustomPainter] 重画，不引 SVG 依赖。
/// 设计尺寸 104×84，默认按 100×84 摆放时等比缩放并居中。
class SomedayArt extends StatelessWidget {
  const SomedayArt({super.key, this.size = const Size(100, 84)});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: const _SomedayPainter(),
      isComplex: true,
      willChange: false,
    );
  }
}

class _SomedayPainter extends CustomPainter {
  const _SomedayPainter();

  static const Size _viewBox = Size(104, 84);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / _viewBox.width,
      size.height / _viewBox.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - _viewBox.width * scale) / 2,
      (size.height - _viewBox.height * scale) / 2,
    );
    canvas.scale(scale);

    // 航线：从左下角虚线飘上来。
    final route = Path()
      ..moveTo(4, 74)
      ..cubicTo(15, 70, 21, 61, 31, 58);
    _drawDashed(
      canvas,
      route,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.muted.withValues(alpha: 0.7),
    );

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    // 机身：整片白纸，右下角压着一片沙色机翼。
    final body = Path()
      ..moveTo(96, 12)
      ..lineTo(30, 46)
      ..lineTo(56, 54)
      ..close();
    canvas.drawPath(body, Paint()..color = AppColors.surface);
    canvas.drawPath(body, outline..color = AppColors.text);

    final wing = Path()
      ..moveTo(96, 12)
      ..lineTo(66, 68)
      ..lineTo(56, 54)
      ..close();
    canvas.drawPath(wing, Paint()..color = AppColors.sandSoft);
    canvas.drawPath(wing, outline..color = AppColors.text);

    // 折痕。
    canvas.drawLine(
      const Offset(38, 42),
      const Offset(58, 52),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.text.withValues(alpha: 0.35),
    );

    canvas.restore();
  }

  /// 把一条路径画成短划线（原型是 `stroke-dasharray: 2 7`）。
  void _drawDashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dash = 2,
    double gap = 7,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_SomedayPainter oldDelegate) => false;
}
