import 'package:flutter/material.dart';

import 'package:node/models/todo_note.dart';
import 'package:node/state/todo_controller.dart';
import 'package:node/theme/tokens.dart';
import 'package:node/widgets/paper_scaffold.dart';

/// 新建 / 编辑待办（同一页，传 [note] 即编辑）。
///
/// 表单只收集「内容、分类、时间」三样；id、创建时间、完成时间都沿用原值，
/// 所以编辑一条已完成的事不会把它变回未完成。
class NoteFormPage extends StatefulWidget {
  const NoteFormPage({super.key, this.note});

  static const routeName = '/note';

  /// 要编辑的待办；为 null 时是新建。
  final TodoNote? note;

  bool get isEditing => note != null;

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  /// 时间不是自由文本：给几个常用档位，点一下就行。
  static const _timeOptions = <String>['上午', '下午', '傍晚', '睡前'];

  late final TextEditingController _content;
  late TodoCategory _category;
  String? _time;

  @override
  void initState() {
    super.initState();
    _content = TextEditingController(text: widget.note?.content ?? '');
    _category = widget.note?.category ?? TodoCategory.work;
    _time = widget.note?.timeLabel;
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  bool get _canSave => _content.text.trim().isNotEmpty;

  void _close() => Navigator.of(context).maybePop();

  void _save() {
    final text = _content.text.trim();
    if (text.isEmpty) return;

    final controller = TodoScope.of(context);
    final old = widget.note;
    if (old == null) {
      controller.add(content: text, category: _category, timeLabel: _time);
    } else {
      controller.update(
        TodoNote(
          id: old.id,
          content: text,
          category: _category,
          timeLabel: _time,
          createdAt: old.createdAt,
          completedAt: old.completedAt,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final note = widget.note;
    if (note == null) return;

    final controller = TodoScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '删除这条待办？',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          '删掉之后，可以在屏幕底部的提示条里点「撤销」找回来。',
          style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    controller.remove(note.id);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('已删除一条待办'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => controller.restore(note),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.isEditing;

    return PaperScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                IconButton(
                  onPressed: _close,
                  tooltip: '关闭',
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
                const Spacer(),
                if (editing)
                  TextButton(
                    onPressed: _confirmDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size(AppSize.tap, AppSize.tap),
                      textStyle: const TextStyle(
                        fontSize: AppText.sm,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('删除'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSize.pageX,
                AppSpace.s2,
                AppSize.pageX,
                AppSpace.s6,
              ),
              children: [
                Text(
                  editing ? '编辑这条待办' : '新建一条待办',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpace.s2),
                Text(
                  editing ? '改完点保存，改坏了就删掉。' : '写下来就行，不用想得太完整。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpace.s5),
                _ContentField(
                  controller: _content,
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppSpace.s5),
                const _FieldLabel('分类'),
                const SizedBox(height: AppSpace.s3),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final category in TodoCategory.values)
                      _ChoicePill(
                        label: category.label,
                        selected: _category == category,
                        onTap: () => setState(() => _category = category),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.s5),
                const _FieldLabel('时间（可选）'),
                const SizedBox(height: AppSpace.s3),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ChoicePill(
                      label: '不设置',
                      selected: _time == null,
                      onTap: () => setState(() => _time = null),
                    ),
                    for (final time in _timeOptionsFor(widget.note?.timeLabel))
                      _ChoicePill(
                        label: time,
                        selected: _time == time,
                        onTap: () => setState(() => _time = time),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // 放进 body 而不是 Scaffold.bottomNavigationBar：
          // 键盘弹起时 body 会缩，保存栏跟着抬到键盘上方；放在 bottomNavigationBar 会被键盘盖住。
          _SaveBar(enabled: _canSave, onSave: _save),
        ],
      ),
    );
  }

  /// 原型里时间有「14:00」这类旧值：编辑时把它也做成一个可点的档位，
  /// 否则打开编辑页会看到一个没有选中任何项的时间行。
  List<String> _timeOptionsFor(String? current) {
    if (current == null || _timeOptions.contains(current)) {
      return _timeOptions;
    }
    return [current, ..._timeOptions];
  }
}

/// 大输入区：minLines 撑到原型的 184 高，键入时继续往下长。
class _ContentField extends StatelessWidget {
  const _ContentField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.sm);

    return TextField(
      controller: controller,
      autofocus: true,
      minLines: 6,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: theme.textTheme.bodyLarge,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: '做什么？比如：周五前把提案终稿发给 Amanda',
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.muted.withValues(alpha: 0.72),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpace.s4),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: AppText.sm,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.muted,
      ),
    );
  }
}

/// 44 高的胶囊，选中的用主色实底，没选中的是纸面加细边。
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
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

/// 底部保存栏：内容为空时按钮变浅、点不动。
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.enabled, required this.onSave});

  final bool enabled;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    // 键盘弹起时 Scaffold 会缩 body，但 MediaQuery 的底部安全区还在；
    // 这时不再补手势条高度，否则保存栏和键盘之间会空一条。
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.up,
      ),
      child: SafeArea(
        top: false,
        bottom: !keyboardOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSize.pageX,
            AppSpace.s3,
            AppSize.pageX,
            AppSpace.s3,
          ),
          child: SizedBox(
            height: 52,
            child: Material(
              color: enabled
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.34),
              borderRadius: radius,
              elevation: enabled ? 6 : 0,
              shadowColor: AppColors.alpha(AppColors.primary, 0.35),
              child: InkWell(
                onTap: enabled ? onSave : null,
                borderRadius: radius,
                child: Center(
                  child: Text(
                    '保存',
                    style: TextStyle(
                      fontSize: AppText.md,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? AppColors.primaryInk
                          : AppColors.primaryInk.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
