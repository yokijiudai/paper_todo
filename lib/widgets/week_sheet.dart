import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../utils/formatters.dart';

/// 从底部弹出「换一周」弹层，返回选中的那一周（周一）。
///
/// [weekCount] 用来在页脚显示「本周 N 件」，由页面传 controller 的统计进来，
/// 弹层本身不依赖 TodoController。
Future<DateTime?> showWeekSheet(
  BuildContext context, {
  required DateTime weekStart,
  required int Function(DateTime weekStart) weekCount,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.alpha(AppColors.text, 0.34),
    builder: (context) =>
        _WeekSheet(initialWeekStart: mondayOf(weekStart), weekCount: weekCount),
  );
}

class _WeekSheet extends StatefulWidget {
  const _WeekSheet({required this.initialWeekStart, required this.weekCount});

  final DateTime initialWeekStart;
  final int Function(DateTime weekStart) weekCount;

  @override
  State<_WeekSheet> createState() => _WeekSheetState();
}

class _WeekSheetState extends State<_WeekSheet> {
  late DateTime _selected = widget.initialWeekStart;
  late DateTime _visibleMonth = DateTime(_selected.year, _selected.month);
  late int _pickerYear = _visibleMonth.year;
  bool _pickingMonth = false;

  static const List<String> _weekdayLabels = [
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
    '日',
  ];

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _pickMonth(int month) {
    setState(() {
      _visibleMonth = DateTime(_pickerYear, month);
      _pickingMonth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSize.pageX,
        AppSpace.s1,
        AppSize.pageX,
        AppSpace.s3 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabber(),
          _header(theme),
          Flexible(
            child: SingleChildScrollView(
              child: _pickingMonth ? _monthPicker(theme) : _calendar(theme),
            ),
          ),
          _footer(theme),
        ],
      ),
    );
  }

  Widget _grabber() => Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(top: AppSpace.s1, bottom: AppSpace.s2),
    decoration: BoxDecoration(
      color: AppColors.alpha(AppColors.text, 0.25),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
  );

  Widget _header(ThemeData theme) {
    return Row(
      children: [
        IconButton(
          onPressed: () =>
              _pickingMonth ? setState(() => _pickerYear--) : _shiftMonth(-1),
          tooltip: _pickingMonth ? '上一年' : '上个月',
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppColors.muted,
        ),
        Expanded(
          child: Center(
            child: InkWell(
              onTap: () => setState(() {
                _pickingMonth = !_pickingMonth;
                _pickerYear = _visibleMonth.year;
              }),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s2,
                  vertical: AppSpace.s1,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pickingMonth
                          ? '$_pickerYear 年'
                          : '${_visibleMonth.year} 年 ${_visibleMonth.month} 月',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () =>
              _pickingMonth ? setState(() => _pickerYear++) : _shiftMonth(1),
          tooltip: _pickingMonth ? '下一年' : '下个月',
          icon: const Icon(Icons.chevron_right_rounded),
          color: AppColors.muted,
        ),
      ],
    );
  }

  Widget _calendar(ThemeData theme) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final gridStart = mondayOf(firstDay);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final rowCount = ((firstDay.weekday - 1 + daysInMonth) / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(height: 2),
                  ),
                ),
              ),
          ],
        ),
        for (var row = 0; row < rowCount; row++)
          _weekRow(addDays(gridStart, row * 7), theme),
      ],
    );
  }

  Widget _weekRow(DateTime rowStart, ThemeData theme) {
    final selected = isSameDay(rowStart, _selected);
    return InkWell(
      onTap: () => setState(() => _selected = rowStart),
      borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      child: Container(
        height: 42,
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: selected
            ? BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              )
            : null,
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    '${addDays(rowStart, i).day}',
                    style: TextStyle(
                      fontSize: AppText.sm,
                      color: _dayColor(addDays(rowStart, i), selected),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _dayColor(DateTime day, bool weekSelected) {
    if (day.month != _visibleMonth.month) {
      return AppColors.alpha(AppColors.muted, 0.45);
    }
    return weekSelected ? AppColors.primaryDeep : AppColors.text;
  }

  Widget _monthPicker(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpace.s2),
        SizedBox(
          height: 148,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpace.s2,
              crossAxisSpacing: AppSpace.s2,
              mainAxisExtent: 44,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final selected =
                  month == _visibleMonth.month &&
                  _pickerYear == _visibleMonth.year;
              return Material(
                color: selected ? AppColors.primary : AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  onTap: () => _pickMonth(month),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Center(
                    child: Text(
                      '$month 月',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selected ? AppColors.primaryInk : AppColors.text,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpace.s3),
      ],
    );
  }

  Widget _footer(ThemeData theme) {
    final count = widget.weekCount(_selected);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '已选 ${weekRange(_selected)} · 本周 $count 件',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpace.s3),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_selected),
              child: const Text('完成'),
            ),
          ),
        ],
      ),
    );
  }
}
