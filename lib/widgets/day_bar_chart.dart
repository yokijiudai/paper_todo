import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../utils/formatters.dart';

/// 一周完成件数的柱状图。
///
/// 7 根柱，选中的那根是橄榄绿、其余是沙色；基线画成手绘感的浅墨线。
/// 点某一列即选中那天（按列宽换算，不依赖柱子的实际宽度）。
class DayBarChart extends StatelessWidget {
  const DayBarChart({
    super.key,
    required this.counts,
    required this.selectedIndex,
    required this.onSelect,
    required this.weekStart,
  });

  /// 原型里的 SVG 是 310 × 132，这里按宽度等比放大。
  static const double _aspect = 310 / 132;

  /// 周一到周日各完成几件，固定 7 项。
  final List<int> counts;

  /// 选中列，0 = 周一。
  final int selectedIndex;

  final ValueChanged<int> onSelect;

  /// 这一周的周一，给无障碍朗读用。
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / _aspect;
        return Semantics(
          label: '${weekRange(weekStart)}每天完成的件数，点按某一天查看当天的完成记录',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final columnWidth = width / 7;
              final index = (details.localPosition.dx / columnWidth)
                  .floor()
                  .clamp(0, 6);
              onSelect(index);
            },
            child: CustomPaint(
              size: Size(width, height),
              painter: _BarChartPainter(
                counts: counts,
                selectedIndex: selectedIndex,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.counts, required this.selectedIndex});

  final List<int> counts;
  final int selectedIndex;

  static const double _barWidth = 20;
  static const double _barRadius = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final columnWidth = size.width / 7;
    final labelTop = size.height - 20;
    const plotTop = 18.0;
    final plotBottom = labelTop - 4;
    final maxCount = math.max(1, counts.reduce(math.max));

    _paintBaseline(canvas, size, plotBottom);
    _paintWeekdayLabels(canvas, columnWidth, labelTop);

    for (var i = 0; i < 7; i++) {
      final count = counts[i];
      final selected = i == selectedIndex;
      final centerX = columnWidth * (i + 0.5);

      // 0 件也留一小截，柱子列不会看起来像「没有位置」。
      final ratio = count == 0 ? 0.0 : count / maxCount;
      final barHeight = count == 0
          ? 3.0
          : math.max(6.0, (plotBottom - plotTop) * ratio);

      final rect = Rect.fromLTWH(
        centerX - _barWidth / 2,
        plotBottom - barHeight,
        _barWidth,
        barHeight,
      );
      final paint = Paint()
        ..color = selected ? AppColors.accent : AppColors.sand;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(_barRadius),
          topRight: const Radius.circular(_barRadius),
        ),
        paint,
      );

      if (count > 0) {
        _paintNumber(
          canvas,
          count: count,
          centerX: centerX,
          top: plotBottom - barHeight - 16,
          selected: selected,
        );
      }
    }
  }

  /// 手绘感的基线：一条有轻微起伏的曲线，而不是直尺线。
  void _paintBaseline(Canvas canvas, Size size, double y) {
    final path = Path()
      ..moveTo(-2, y)
      ..cubicTo(
        size.width * 0.22,
        y - 1.6,
        size.width * 0.48,
        y + 1.4,
        size.width * 0.72,
        y - 0.4,
      )
      ..quadraticBezierTo(size.width * 0.9, y - 1.2, size.width + 2, y - 0.6);
    final paint = Paint()
      ..color = AppColors.alpha(AppColors.text, 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, paint);
  }

  void _paintWeekdayLabels(Canvas canvas, double columnWidth, double top) {
    for (var i = 0; i < 7; i++) {
      final selected = i == selectedIndex;
      final painter = TextPainter(
        text: TextSpan(
          text: weekdayShort(i + 1),
          style: TextStyle(
            fontSize: 12,
            height: 1,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(columnWidth * (i + 0.5) - painter.width / 2, top),
      );
    }
  }

  void _paintNumber(
    Canvas canvas, {
    required int count,
    required double centerX,
    required double top,
    required bool selected,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: '$count',
        style: TextStyle(
          fontSize: 12,
          height: 1,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.accent : AppColors.muted,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(centerX - painter.width / 2, top));
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      !listEquals(oldDelegate.counts, counts);
}
