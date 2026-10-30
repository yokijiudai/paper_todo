import 'package:flutter/material.dart';

import 'package:paper_todo/models/todo_note.dart';
import 'package:paper_todo/theme/tokens.dart';

/// 分类小标签：工作 / 生活 / 学习 / 灵感。
///
/// 四个分类的底色与字色都在这里定义，别处只传 [category]，
/// 避免同一个分类在不同页面出现两种绿。
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});

  final TodoCategory category;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (category) {
      TodoCategory.work => (AppColors.primarySoft, AppColors.primaryDeep),
      TodoCategory.life => (AppColors.accentSoft, AppColors.link),
      TodoCategory.study => (AppColors.sandSoft, AppColors.primaryDeep),
      // 原型里没有「灵感」的配色，取沙色底 + 墨色字（对比度约 9.8:1）。
      TodoCategory.idea => (AppColors.sand, AppColors.text),
    };

    return Container(
      height: AppSize.chip,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      // Row + min 尺寸让胶囊只包住文字；用 alignment 会把它撑满整行。
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            category.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: 0.2,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
