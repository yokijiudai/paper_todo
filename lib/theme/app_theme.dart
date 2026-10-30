import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// 全局主题：把 tokens 收口成一份 `ThemeData`，页面里不再写死字号和颜色。
abstract final class AppTheme {
  /// 标题衬线字体。字体文件未就位时由 [serifFallback] 兜底。
  static const serif = 'NotoSerifSC';
  static const serifFallback = <String>['Songti SC', 'STSong', 'serif'];

  /// 透明状态栏 + 深色图标；底部导航栏用纸面白，避免手势条处出现黑色色块。
  static const overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: AppColors.line,
  );

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryInk,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.accent,
      onSecondary: AppColors.primaryInk,
      secondaryContainer: AppColors.accentSoft,
      onSecondaryContainer: AppColors.link,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      onError: AppColors.primaryInk,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
    );

    final textTheme = TextTheme(
      displayLarge: _serif(
        size: AppText.xxl,
        height: 1.25,
        letterSpacing: -0.5,
      ),
      headlineSmall: _serif(size: AppText.xl, height: 1.35),
      titleLarge: _sans(size: AppText.lg, weight: FontWeight.w600, height: 1.4),
      titleMedium: _sans(
        size: AppText.md,
        weight: FontWeight.w600,
        height: 1.45,
      ),
      bodyLarge: _sans(size: AppText.md, height: 1.6),
      bodyMedium: _sans(size: AppText.sm, height: 1.6),
      bodySmall: _sans(size: AppText.xs, height: 1.5, color: AppColors.muted),
      labelSmall: _sans(
        size: 11,
        weight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.muted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: AppSpace.s4,
      ),
      iconTheme: const IconThemeData(color: AppColors.text, size: 24),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.alpha(AppColors.primary, 0.18),
        selectionHandleColor: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: _sans(size: AppText.sm, color: AppColors.primaryInk),
        actionTextColor: AppColors.sand,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.fromLTRB(
          AppSpace.s4,
          0,
          AppSpace.s4,
          AppSpace.s4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      splashColor: AppColors.alpha(AppColors.primary, 0.06),
      highlightColor: AppColors.alpha(AppColors.primary, 0.04),
      visualDensity: VisualDensity.standard,
    );
  }

  static TextStyle _serif({
    required double size,
    double? height,
    double? letterSpacing,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.text,
  }) {
    return TextStyle(
      fontFamily: serif,
      fontFamilyFallback: serifFallback,
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle _sans({
    required double size,
    double? height,
    double? letterSpacing,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
  }) {
    return TextStyle(
      fontSize: size,
      height: height,
      letterSpacing: letterSpacing,
      fontWeight: weight,
      color: color,
    );
  }
}
