import 'package:flutter/material.dart';

import 'package:paper_todo/theme/tokens.dart';

/// 底部标签栏：今天 / 以后 / 回顾 三格，最右边一格上方浮着「新建」圆钮。
///
/// `index`：0 = 今天，1 = 以后，2 = 回顾。切页由 [RootShell] 的 `IndexedStack`
/// 负责，这里只发信号，不做导航。
///
/// 圆钮比栏面高 [AppSize.tabBarLift]，所以整个组件比栏面多留这么多高度：
/// 按钮因此完整落在自己的命中区内，凸出来的那一截也点得到。
class DiyTabBar extends StatelessWidget {
  const DiyTabBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  /// 标签栏总高度（含底部手势条与上浮部分）。
  static double heightOf(BuildContext context) =>
      AppSize.tabBar +
      AppSize.tabBarLift +
      MediaQuery.paddingOf(context).bottom;

  /// 栏面左右留白：浮起的圆钮和栏内格子用同一份，第四格中心才对得上。
  static const double _sideInset = AppSpace.s4;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = AppSize.tabBar + bottomInset;

    return SizedBox(
      height: AppSize.tabBarLift + barHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.line)),
                boxShadow: AppShadows.up,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: SizedBox(
                  height: AppSize.tabBar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _sideInset),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _TabItem(
                            label: '今天',
                            icon: Icons.checklist_rounded,
                            selectedIcon: Icons.checklist_rounded,
                            selected: index == 0,
                            onTap: () => onSelect(0),
                          ),
                        ),
                        Expanded(
                          child: _TabItem(
                            label: '以后',
                            icon: Icons.bookmark_border_rounded,
                            selectedIcon: Icons.bookmark_rounded,
                            selected: index == 1,
                            onTap: () => onSelect(1),
                          ),
                        ),
                        Expanded(
                          child: _TabItem(
                            label: '回顾',
                            icon: Icons.bar_chart_outlined,
                            selectedIcon: Icons.bar_chart_rounded,
                            selected: index == 2,
                            onTap: () => onSelect(2),
                          ),
                        ),
                        // 第四格只放文字；圆钮由上面的浮层盖在这一格上方。
                        const Expanded(child: _AddLabel()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _sideInset),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) const Expanded(child: SizedBox()),
                  Expanded(
                    child: Center(child: _AddButton(onTap: onAdd)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: false,
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.4,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 第四格的文字。上面留出和图标等高的位置，让「新建」与其他标签在同一行。
class _AddLabel extends StatelessWidget {
  const _AddLabel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 20),
        SizedBox(height: 2),
        Text(
          '新建',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '新建待办',
      // 用手写阴影代替 Material 的 elevation：后者带色阴影在浅色底上会晕成
      // 一圈「光环」，原型用的是更柔的暖褐投影。
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppShadows.lift,
        ),
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: AppSize.tap,
              height: AppSize.tap,
              child: Icon(
                Icons.add_rounded,
                size: 24,
                color: AppColors.primaryInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
