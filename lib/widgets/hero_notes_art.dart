import 'package:flutter/material.dart';

import 'package:node/theme/tokens.dart';

/// 首屏右上角的「叠纸」插画：三张微微旋转的便签，最前面一张有字迹和勾。
///
/// 用 [CustomPainter] 画，不依赖 SVG 资源；尺寸按设计稿 112×108，
/// 放进布局时用 [size] 指定即可。
class HeroNotesArt extends StatelessWidget {
  const HeroNotesArt({super.key, this.size = const Size(112, 108)});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: const _HeroNotesPainter(),
      isComplex: true,
      willChange: false,
    );
  }
}

class _HeroNotesPainter extends CustomPainter {
  const _HeroNotesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    // 后面两张：沙色与浅绿，旋转方向相反。
    _drawNote(
      canvas,
      const Rect.fromLTWH(-42, -50, 50, 56),
      -0.24,
      AppColors.sand,
    );
    _drawNote(
      canvas,
      const Rect.fromLTWH(-6, -52, 50, 56),
      0.12,
      AppColors.accentSoft,
    );

    // 最前面一张：近白的纸，三条字迹 + 一枚绿勾。
    _drawNote(
      canvas,
      const Rect.fromLTWH(-20, -34, 62, 70),
      -0.05,
      const Color(0xFFFFFDF9),
      lines: 3,
      withCheck: true,
    );

    canvas.restore();
  }

  void _drawNote(
    Canvas canvas,
    Rect rect,
    double angle,
    Color color, {
    int lines = 0,
    bool withCheck = false,
  }) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(angle);

    final local = Rect.fromCenter(
      center: Offset.zero,
      width: rect.width,
      height: rect.height,
    );
    final rrect = RRect.fromRectAndRadius(local, const Radius.circular(5));
    final path = Path()..addRRect(rrect);

    canvas.drawShadow(path, const Color(0x59000000), 7, false);
    canvas.drawRRect(rrect, Paint()..color = color);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x1F000000),
    );

    if (lines > 0) {
      final ink = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.text.withValues(alpha: 0.28);
      for (var i = 0; i < lines; i++) {
        final y = -local.height / 2 + 17 + i * 11;
        final width = i == lines - 1 ? local.width * 0.42 : local.width * 0.58;
        canvas.drawLine(
          Offset(-local.width * 0.28, y),
          Offset(-local.width * 0.28 + width, y),
          ink,
        );
      }
    }

    if (withCheck) {
      final dot = Offset(local.width * 0.20, local.height * 0.24);
      canvas.drawCircle(dot, 7.5, Paint()..color = AppColors.accent);
      final tick = Path()
        ..moveTo(dot.dx - 3.4, dot.dy)
        ..lineTo(dot.dx - 0.8, dot.dy + 2.8)
        ..lineTo(dot.dx + 3.6, dot.dy - 2.6);
      canvas.drawPath(
        tick,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.9
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = AppColors.primaryInk,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeroNotesPainter oldDelegate) => false;
}

/// 供布局计算用的插画宽高比：112 × 108。
const double heroArtAspectRatio = 112 / 108;
