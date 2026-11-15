import 'package:flutter/material.dart';

import 'package:paper_todo/theme/tokens.dart';

/// 44 高的胶囊选择：选中的用主色实底，没选中的是纸面加细边。
///
/// 编辑页和「以后」页的快速记录都用它，两处不再各写一套。
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = StadiumBorder(
      side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Container(
            height: AppSize.tap,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            // widthFactor 让胶囊贴着文字收缩；否则 Center 会吃满 Wrap 给的宽度。
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppText.sm,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.primaryInk : AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
