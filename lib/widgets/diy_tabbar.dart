import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 底部标签栏：两格 + 中间凸起的「新建」。
///
/// `index`：0 = 今天，1 = 回顾。切页由 [RootShell] 的 `IndexedStack` 负责，
/// 这里只发信号，不做导航。
///
/// 圆钮比栏面高 18，所以整个组件比栏面多留 [AppSize.tabBarLift] 的高度：
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _TabItem(
                          label: '今天',
                          icon: Icons.wb_sunny_outlined,
                          selectedIcon: Icons.wb_sunny_rounded,
                          selected: index == 0,
                          onTap: () => onSelect(0),
                        ),
                      ),
                      const Spacer(),
                      Expanded(
                        child: _TabItem(
                          label: '回顾',
                          icon: Icons.bar_chart_outlined,
                          selectedIcon: Icons.bar_chart_rounded,
                          selected: index == 1,
                          onTap: () => onSelect(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: _AddButton(onTap: onAdd)),
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
                fontWeight: FontWeight.w600,
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

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '新建待办',
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: AppColors.alpha(AppColors.primary, 0.38),
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
    );
  }
}