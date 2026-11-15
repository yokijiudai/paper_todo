import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:paper_todo/theme/tokens.dart';

/// 卡片顶上的一小段纸胶带（原型 `.tape`）。
///
/// 只做装饰，放在 [Stack] 里用 [Positioned] 压住卡片上沿：
/// `top: -11, left: 22`。展开动画、点击区域之类的都别加在它身上。
class PaperTape extends StatelessWidget {
  const PaperTape({
    super.key,
    this.width = 72,
    this.height = 22,
    this.angle = -3.5,
  });

  final double width;
  final double height;

  /// 旋转角度（度），负值向左歪。
  final double angle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.sand.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F784820),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
