import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:paper_todo/models/todo_note.dart';
import 'package:paper_todo/state/todo_controller.dart';
import 'package:paper_todo/theme/tokens.dart';
import 'package:paper_todo/widgets/choice_pill.dart';
import 'package:paper_todo/widgets/later_note_tile.dart';
import 'package:paper_todo/widgets/paper_scaffold.dart';
import 'package:paper_todo/widgets/paper_tape.dart';
import 'package:paper_todo/widgets/primary_button.dart';
import 'package:paper_todo/widgets/someday_art.dart';

import 'note_form_page.dart';

/// 以后：不着急的事先记着，哪天有空再挪到今天。
///
/// 上面是一张「纸条」，随手写一行就能存进以后；下面是放着的清单，
/// 每行右侧一个按钮把它挪回今天的清单。
class LaterPage extends StatefulWidget {
  const LaterPage({super.key});

  @override
  State<LaterPage> createState() => _LaterPageState();
}

class _LaterPageState extends State<LaterPage> {
  /// 「以后」页的默认分类跟着原型的示例走：生活。
  static const _defaultCategory = TodoCategory.life;

  final _content = TextEditingController();
  final _focus = FocusNode();
  TodoCategory _category = _defaultCategory;

  @override
  void initState() {
    super.initState();
    // 输入框内容变化只影响「先记着」按钮的可用状态，重建整页最省心。
    _content.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _content
      ..removeListener(_onTextChanged)
      ..dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _canSave => _content.text.trim().isNotEmpty;

  void _save() {
    final text = _content.text.trim();
    if (text.isEmpty) return;

    final controller = TodoScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    controller.add(
      content: text,
      category: _category,
      bucket: TodoBucket.later,
    );
    _content.clear();
    _focus.unfocus();
    messenger.showSnackBar(
      const SnackBar(content: Text('记在「以后」了'), duration: Duration(seconds: 2)),
    );
  }

  void _moveToToday(TodoController controller, TodoNote note) {
    final messenger = ScaffoldMessenger.of(context);
    controller.moveToToday(note.id);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('挪到今天了'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => controller.moveToLater(note.id),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _edit(TodoNote note) {
    Navigator.of(context).pushNamed(NoteFormPage.routeName, arguments: note);
  }

  @override
  Widget build(BuildContext context) {
    final controller = TodoScope.of(context);
    final theme = Theme.of(context);
    final later = controller.later;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSize.pageX,
        AppSpace.s4,
        AppSize.pageX,
        AppSpace.s5,
      ),
      children: [
        Text(
          '以后 · 先记着',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('不着急的事，\n放这里', style: theme.textTheme.displayLarge),
              ),
            ),
            const SizedBox(width: AppSpace.s2),
            const SomedayArt(),
          ],
        ),
        const SizedBox(height: AppSpace.s3),
        Text(
          '想起什么写一行，哪天有空再挪到今天。',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpace.s6),
        Stack(
          clipBehavior: Clip.none,
          children: [
            PaperCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s4,
                AppSpace.s5,
                AppSpace.s4,
                AppSpace.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '想做的事',
                    style: TextStyle(
                      fontSize: AppText.xs,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpace.s2),
                  _SlipField(controller: _content, focusNode: _focus),
                  const SizedBox(height: AppSpace.s4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in TodoCategory.values)
                        ChoicePill(
                          label: category.label,
                          selected: _category == category,
                          onTap: () => setState(() => _category = category),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s4),
                  PrimaryButton(
                    label: '先记着',
                    onPressed: _canSave ? _save : null,
                  ),
                ],
              ),
            ),
            const Positioned(top: -11, left: 22, child: PaperTape()),
          ],
        ),
        const SizedBox(height: AppSpace.s5),
        const _GroupHeader(),
        const SizedBox(height: AppSpace.s3),
        if (later.isEmpty)
          const _EmptyNote()
        else
          for (var i = 0; i < later.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            LaterNoteTile(
              note: later[i],
              now: controller.now,
              onTap: () => _edit(later[i]),
              onMoveToToday: () => _moveToToday(controller, later[i]),
            ),
          ],
        const SizedBox(height: AppSpace.s5),
        Center(
          child: Text(
            '不着急，想起来再回来。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// 带数量的分组标题：一条细线拉到右边，和首页的两段同一个样子。
class _GroupHeader extends StatelessWidget {
  const _GroupHeader();

  @override
  Widget build(BuildContext context) {
    final count = TodoScope.of(context).later.length;
    return Row(
      children: [
        Text(
          '放着的 $count 件',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: AppSpace.s3),
        const Expanded(
          child: Divider(height: 1, thickness: 1, color: AppColors.line),
        ),
      ],
    );
  }
}

/// 还没记过东西时的两行话。
class _EmptyNote extends StatelessWidget {
  const _EmptyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '还没放什么事。',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            '想起什么，在上面写一行先记着。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.muted.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

/// 纸条上的输入区：透明底、只在下方画一条虚线，聚焦时变主色。
class _SlipField extends StatelessWidget {
  const _SlipField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 3,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '比如：学做一次手冲咖啡',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.muted.withValues(alpha: 0.72),
              ),
              // 原型是一条虚线，不用 Material 的描边输入框。
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: focusNode,
          builder: (context, _) => SizedBox(
            height: 1,
            width: double.infinity,
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: focusNode.hasFocus ? AppColors.primary : AppColors.line,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 1px 的短虚线。
class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const dash = 4.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0.6),
        Offset(math.min(x + dash, size.width), 0.6),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
