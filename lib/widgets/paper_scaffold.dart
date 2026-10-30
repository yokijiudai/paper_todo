import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 纸面脚手架：暖色底 + 纸纹 + 系统栏配色，所有页面都从这里起。
///
/// 底部栏走 `Scaffold.bottomNavigationBar`，因此键盘弹起时不会盖住输入框；
/// 内容区不需要自己再让出手势条。
class PaperScaffold extends StatelessWidget {
  const PaperScaffold({
    super.key,
    required this.body,
    this.bottomBar,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final Widget? bottomBar;
  final bool resizeToAvoidBottomInset;

  static const texturePath = 'assets/textures/paper.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _PaperTexture(),
          SafeArea(
            top: true,
            bottom: false,
            child: body,
          ),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

/// 铺满整屏的纸纹。包一层 [RepaintBoundary]，滚动时不会连纹理一起重绘。
class _PaperTexture extends StatelessWidget {
  const _PaperTexture();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Opacity(
          opacity: 0.07,
          child: Image.asset(
            PaperScaffold.texturePath,
            repeat: ImageRepeat.repeat,
            fit: BoxFit.none,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

/// 卡片：纸面白 + 圆角 16 + 软阴影（原型 `.card`）。
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.s4),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.md,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}