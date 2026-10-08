import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../Widgets/zbutton.dart';


class MonthYearPicker extends StatefulWidget {
  final ValueChanged<String> onMonthYearSelected; // Changed to String
  final DateTime? initialDate;
  final int minYear;
  final int maxYear;
  final bool disablePastDates;

  const MonthYearPicker({
    super.key,
    required this.onMonthYearSelected,
    this.initialDate,
    this.minYear = 1900,
    this.maxYear = 2100,
    this.disablePastDates = false,
  });

  @override
  MonthYearPickerState createState() => MonthYearPickerState();
}

class MonthYearPickerState extends State<MonthYearPicker> {
  late DateTime _selectedDate;
  late int _selectedYear;
  bool _showYearSelector = false;
  DateTime? _pendingSelection;

  late ScrollController _yearScrollController;
  final List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final List<String> _monthFullNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    // If past dates are disabled and initial date is in past, use current month/year
    if (widget.disablePastDates && widget.initialDate != null) {
      final initial = widget.initialDate!;
      if (initial.year < now.year ||
          (initial.year == now.year && initial.month < now.month)) {
        _selectedDate = DateTime(now.year, now.month, 1);
      } else {
        _selectedDate = DateTime(initial.year, initial.month, 1);
      }
    } else {
      _selectedDate = widget.initialDate ?? DateTime(now.year, now.month, 1);
    }

    _selectedYear = _selectedDate.year;
    _pendingSelection = _selectedDate;
    _yearScrollController = ScrollController();
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  String _formatSelectedMonthYear(DateTime date) {
    return '${_monthFullNames[date.month - 1]}, ${date.year}';
  }

  // NEW METHOD: Format date as "YYYY-MM" with zero-padded month
  String _formatForApi(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  void _onMonthTapped(int month) {
    final newDate = DateTime(_selectedYear, month, 1);

    // Check if past dates are disabled and date is in past
    if (widget.disablePastDates && _isDateBeforeToday(newDate)) {
      return;
    }

    setState(() {
      _pendingSelection = newDate;
    });
  }

  void _confirmSelection() {
    if (_pendingSelection != null) {
      // Double-check that the pending selection is valid
      if (widget.disablePastDates && _isDateBeforeToday(_pendingSelection!)) {
        return;
      }

      setState(() {
        _selectedDate = _pendingSelection!;
        _selectedYear = _pendingSelection!.year;
      });

      // Call the callback with formatted string
      widget.onMonthYearSelected(_formatForApi(_pendingSelection!));
      Navigator.of(context).pop();
    }
  }

  void _selectCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _pendingSelection = DateTime(now.year, now.month, 1);
      _selectedYear = now.year;
    });
  }

  void _changeYear(int year) {
    // If past dates are disabled, don't allow selecting years before current year
    if (widget.disablePastDates && year < DateTime.now().year) {
      return;
    }

    setState(() {
      _selectedYear = year;

      // Update pending selection to keep the same month in new year
      if (_pendingSelection != null) {
        final newMonth = DateTime(year, _pendingSelection!.month, 1);
        // If we're selecting the current year, ensure we don't select past months
        if (widget.disablePastDates && year == DateTime.now().year) {
          if (newMonth.month < DateTime.now().month) {
            _pendingSelection = DateTime(year, DateTime.now().month, 1);
          } else {
            _pendingSelection = newMonth;
          }
        } else {
          _pendingSelection = newMonth;
        }
      }
    });
  }

  void _navigateYear(int offset) {
    final newYear = _selectedYear + offset;

    // Check bounds
    if (newYear < widget.minYear || newYear > widget.maxYear) return;

    // If past dates are disabled, don't allow navigating to past years
    if (widget.disablePastDates && newYear < DateTime.now().year) {
      return;
    }

    setState(() {
      _selectedYear = newYear;

      // Update pending selection
      if (_pendingSelection != null) {
        final newMonth = DateTime(newYear, _pendingSelection!.month, 1);
        // If we're in current year, ensure we don't select past months
        if (widget.disablePastDates && newYear == DateTime.now().year) {
          if (newMonth.month < DateTime.now().month) {
            _pendingSelection = DateTime(newYear, DateTime.now().month, 1);
          } else {
            _pendingSelection = newMonth;
          }
        } else {
          _pendingSelection = newMonth;
        }
      }
    });
  }

  void _scrollToSelectedYear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _selectedYear - widget.minYear;
      final row = index ~/ 3; // because crossAxisCount = 3
      const rowHeight = 25.0; // approximate height per row
      final offset = (row * rowHeight) - 60; // center-ish
      if (_yearScrollController.hasClients) {
        _yearScrollController.animateTo(
          offset.clamp(0.0, _yearScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isDateBeforeToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, 1);
    final compareDate = DateTime(date.year, date.month, 1);
    return compareDate.isBefore(today);
  }

  bool _isMonthDisabled(int month, int year) {
    if (!widget.disablePastDates) return false;

    final now = DateTime.now();
    final selectedDate = DateTime(year, month, 1);
    return selectedDate.isBefore(DateTime(now.year, now.month, 1));
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final showYearPanel = _showYearSelector;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: showYearPanel ? 500 : 340,
        height: 450,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // LEFT: Year selector (slides in by width expansion)
            if (showYearPanel) ...[
              SizedBox(
                width: 180,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          locale.selectYear,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color.primary.withValues(alpha: .7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Year navigation
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left, color: color.secondary),
                            onPressed: () => _navigateYear(-12),
                            tooltip: 'Previous 12 years',
                          ),
                          Text(
                            '${widget.minYear}-${widget.maxYear}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color.primary.withValues(alpha: .7),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right, color: color.secondary),
                            onPressed: () => _navigateYear(12),
                            tooltip: 'Next 12 years',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: GridView.builder(
                        controller: _yearScrollController,
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: widget.maxYear - widget.minYear + 1,
                        itemBuilder: (context, index) {
                          final year = widget.minYear + index;
                          final isSelected = year == _selectedYear;
                          final isPastYear = widget.disablePastDates && year < DateTime.now().year;

                          return InkWell(
                            onTap: isPastYear ? null : () => _changeYear(year),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? color.primary : color.surface,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: isPastYear ? color.outline.withValues(alpha: .3) : Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  year.toString(),
                                  style: TextStyle(
                                    color: isSelected ? color.surface :
                                    isPastYear ? color.outline.withValues(alpha: .5) : color.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: color.outlineVariant),
            ],

            // RIGHT: Month selection content
            Expanded(
              child: Padding(
                padding: _showYearSelector? const EdgeInsets.all(8.0) : EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Selected month/year display (header)
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: color.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatSelectedMonthYear(_pendingSelection ?? _selectedDate),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: color.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                        // NEW: Display API format in header
                        if (_pendingSelection != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _formatForApi(_pendingSelection!),
                              style: TextStyle(
                                fontSize: 12,
                                color: color.outline.withValues(alpha: 0.7),
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Year navigation header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() => _showYearSelector = !_showYearSelector);
                                if (_showYearSelector) _scrollToSelectedYear();
                              },
                              child: Text(
                                _selectedYear.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color.primary.withValues(alpha: .9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ),
                          IconButton(
                            iconSize: 20,
                            icon: Icon(Icons.chevron_left, color: color.secondary),
                            onPressed: () => _navigateYear(-1),
                            tooltip: 'Previous year',
                          ),
                          IconButton(
                            iconSize: 20,
                            icon: Icon(Icons.chevron_right, color: color.secondary),
                            onPressed: () => _navigateYear(1),
                            tooltip: 'Next year',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Month grid (3x4 layout)
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final isSelected = _pendingSelection != null
                              ? _pendingSelection!.month == month && _pendingSelection!.year == _selectedYear
                              : _selectedDate.month == month && _selectedDate.year == _selectedYear;
                          final isDisabled = _isMonthDisabled(month, _selectedYear);
                          final isCurrentMonth = month == DateTime.now().month &&
                              _selectedYear == DateTime.now().year;

                          return InkWell(
                            onTap: isDisabled ? null : () => _onMonthTapped(month),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.primary
                                    : isCurrentMonth
                                    ? color.primary.withValues(alpha: .1)
                                    : color.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected
                                      ? color.primary
                                      : isCurrentMonth
                                      ? color.primary
                                      : color.outline.withValues(alpha: .3),
                                  width: isSelected || isCurrentMonth ? 1 : 0.5,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _monthNames[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? color.surface
                                            : isDisabled
                                            ? color.outline.withValues(alpha: 0.5)
                                            : color.secondary,
                                        fontWeight: isSelected || isCurrentMonth
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                    // NEW: Show month number with zero padding
                                    Text(
                                      month.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        color: isSelected
                                            ? color.surface.withValues(alpha: 0.8)
                                            : isDisabled
                                            ? color.outline.withValues(alpha: 0.4)
                                            : color.secondary.withValues(alpha: 0.7),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Footer buttons
                    Row(
                      children: [
                        ZOutlineButton(
                          height: 30,
                          width: 90,
                          onPressed: _selectCurrentMonth,
                          label: Text(locale.current),
                        ),
                        const SizedBox(width: 8),
                        ZOutlineButton(
                          isActive: true,
                          width: 90,
                          height: 30,
                          onPressed: _pendingSelection != null ? _confirmSelection : null,
                          label: Text(locale.selectKeyword),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}