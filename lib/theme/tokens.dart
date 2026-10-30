import 'package:flutter/material.dart';

/// 设计变量，逐条对应 `design/tokens.css`。
///
/// 全部为 `static const`，不建实例；颜色命名保持与 CSS 变量可对照。
/// CSS 里 `rgba(120, 72, 30, .08)` 这类透明度，用 `0x14` + 色值表达（.08 × 255 ≈ 20 = 0x14），
/// 不用已废弃的 `withOpacity`。
abstract final class AppColors {
  // 纸与墨
  static const bg = Color(0xFFF6EFE6);
  static const surface = Color(0xFFFFF9F2);
  static const surface2 = Color(0xFFF1E6D8);
  static const text = Color(0xFF2B1D14);
  static const muted = Color(0xFF6E5A4B);
  static const line = Color(0xFFE7D9C8);

  // 主色：陶土
  static const primary = Color(0xFFA9542A);
  static const primaryInk = Color(0xFFFFFFFF);
  static const primarySoft = Color(0xFFF2E1D4);
  static const primaryDeep = Color(0xFF6F3218);

  // 点缀：橄榄
  static const accent = Color(0xFF5E7A4A);
  static const accentSoft = Color(0xFFE5EBDC);
  static const link = Color(0xFF52703F);

  // 沙色
  static const sand = Color(0xFFE9CFA9);
  static const sandDeep = Color(0xFFD8B27B);
  static const sandSoft = Color(0xFFF0E2CE);

  static const danger = Color(0xFF8C3B24);

  /// 纸纹、投影等需要按颜色换算透明度的情况，统一从这里取。
  static Color alpha(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}

/// 间距：4 的倍数。
abstract final class AppSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 48.0;
  static const s8 = 64.0;
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const full = 999.0;
}

abstract final class AppSize {
  /// 页面左右留白（原型 `--page-x`）。
  static const pageX = 20.0;

  /// 最小点击区。
  static const tap = 44.0;

  /// 标签栏内容区高度（不含手势条）。
  static const tabBar = 49.0;

  /// 中间「新建」按钮上浮的距离。
  static const tabBarLift = 18.0;

  /// 勾选圈视觉直径。
  static const check = 24.0;

  /// 分类小标签高度。
  static const chip = 22.0;
}

abstract final class AppText {
  static const xs = 12.0;
  static const sm = 14.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

/// 三档阴影，来自 `--shadow-sm / -md / -lg`。
abstract final class AppShadows {
  static const sm = <BoxShadow>[
    BoxShadow(color: Color(0x14784820), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const md = <BoxShadow>[
    BoxShadow(color: Color(0x1F784820), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const lift = <BoxShadow>[
    BoxShadow(color: Color(0x29784820), blurRadius: 28, offset: Offset(0, 10)),
  ];

  /// 标签栏向上投的阴影（原型是 `0 -6px 20px`）。
  static const up = <BoxShadow>[
    BoxShadow(color: Color(0x14784820), blurRadius: 20, offset: Offset(0, -6)),
  ];
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 200);
  static const ease = Cubic(0.2, 0.8, 0.2, 1);

  /// 系统开启「减弱动态效果」时统一退化为零时长。
  static Duration scaled(BuildContext context, Duration duration) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Duration.zero : duration;
  }
}