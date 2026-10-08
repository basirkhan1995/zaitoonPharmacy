import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../l10n/app_localizations.dart';
import '../Widgets/zbutton.dart';

class AfghanDatePicker extends StatefulWidget {
  final ValueChanged<Jalali> onDateSelected;
  final Jalali? initialDate;
  final int minYear;
  final int maxYear;
  final bool disablePastDates; // New parameter

  const AfghanDatePicker({
    super.key,
    required this.onDateSelected,
    this.initialDate,
    this.minYear = 1300,
    this.maxYear = 1500,
    this.disablePastDates = false, // Default to false
  });

  @override
  AfghanDatePickerState createState() => AfghanDatePickerState();
}

class AfghanDatePickerState extends State<AfghanDatePicker> {
  late Jalali _selectedDate;
  late Jalali _currentMonth;
  late Jalali _today;
  final List<String> _weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
  bool _showYearSelector = false;
  late int _selectedYear;
  Jalali? _pendingSelection;

  late ScrollController _yearScrollController;

  @override
  void initState() {
    super.initState();
    _today = Jalali.now();

    // If past dates are disabled and initial date is in past, use today
    if (widget.disablePastDates && widget.initialDate != null && widget.initialDate!.compareTo(_today) < 0) {
      _selectedDate = _today;
    } else {
      _selectedDate = widget.initialDate ?? _today;
    }

    _currentMonth = Jalali(_selectedDate.year, _selectedDate.month, 1);
    _selectedYear = _selectedDate.year;
    _yearScrollController = ScrollController();
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  String _toPersianNumbers(String input) {
    const english = ['0','1','2','3','4','5','6','7','8','9'];
    const persian = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], persian[i]);
    }
    return input;
  }

  String _formatSelectedDate(Jalali date) {
    final weekday = _getFullWeekdayName(date.weekDay);
    final month = _getAfghanMonthName(date.month);
    final day = _toPersianNumbers(date.day.toString().padLeft(2,'0'));
    final year = _toPersianNumbers(date.year.toString());
    return '$weekday، $month $day/$year';
  }

  bool _isSameDate(Jalali d1, Jalali d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  void _onDateTapped(Jalali date) {
    // Check if past dates are disabled and date is in past
    if (widget.disablePastDates && date.compareTo(_today) < 0) {
      return;
    }
    setState(() => _pendingSelection = date);
  }

  void _confirmSelection() {
    if (_pendingSelection != null) {
      // Double-check that the pending selection is valid
      if (widget.disablePastDates && _pendingSelection!.compareTo(_today) < 0) {
        return;
      }

      setState(() {
        _selectedDate = _pendingSelection!;
        _selectedYear = _pendingSelection!.year;
      });
      widget.onDateSelected(_pendingSelection!);
      Navigator.of(context).pop();
    }
  }

  void _selectToday() {
    setState(() {
      _pendingSelection = _today;
      _selectedDate = _today;
      _currentMonth = Jalali(_today.year, _today.month, 1);
      _selectedYear = _today.year;
    });
  }

  void _navigateMonth(int offset) {
    setState(() {
      int newMonth = _currentMonth.month + offset;
      int newYear = _currentMonth.year;

      if (newMonth > 12) {
        newMonth = 1;
        newYear += 1;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear -= 1;
      }

      // If past dates are disabled and trying to navigate to past months, limit to current month
      if (widget.disablePastDates) {
        final newMonthDate = Jalali(newYear, newMonth, 1);
        if (newMonthDate.year < _today.year ||
            (newMonthDate.year == _today.year && newMonthDate.month < _today.month)) {
          _currentMonth = Jalali(_today.year, _today.month, 1);
          _selectedYear = _today.year;
          return;
        }
      }

      _currentMonth = Jalali(newYear, newMonth, 1);
      _selectedYear = newYear;
    });
  }

  void _changeYear(int year) {
    // If past dates are disabled, don't allow selecting years before current year
    if (widget.disablePastDates && year < _today.year) {
      return;
    }

    setState(() {
      _selectedYear = year;

      // If we're in the current year, make sure we don't go to a past month
      if (widget.disablePastDates && year == _today.year) {
        final currentMonth = _currentMonth.month;
        if (currentMonth < _today.month) {
          _currentMonth = Jalali(year, _today.month, 1);
        } else {
          _currentMonth = Jalali(year, currentMonth, 1);
        }
      } else {
        _currentMonth = Jalali(year, _currentMonth.month, 1);
      }

      _showYearSelector = false;
    });
  }

  void _scrollToSelectedYear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = _selectedYear - widget.minYear;
      final row = index ~/ 3; // 3 columns
      const rowHeight = 25.0;
      final offset = (row * rowHeight) - 60;
      if (_yearScrollController.hasClients) {
        _yearScrollController.animateTo(
          offset.clamp(0.0, _yearScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper method to check if a date is disabled
  bool _isDateDisabled(Jalali date) {
    return widget.disablePastDates && date.compareTo(_today) < 0;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final monthLength = _currentMonth.monthLength;
    final firstWeekdayOfMonth = _currentMonth.weekDay;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: _showYearSelector ? 500 : 340,
        height: 450,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.surface,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            // Year selector panel
            if (_showYearSelector)
              SizedBox(
                width: 180,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(locale.selectYear, style: TextStyle(fontWeight: FontWeight.bold, color: color.primary.withValues(alpha: .7))),
                      ],
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
                          final selected = year == _selectedYear;
                          final isPastYear = widget.disablePastDates && year < _today.year;

                          return InkWell(
                            onTap: isPastYear ? null : () => _changeYear(year),
                            child: Container(
                              decoration: BoxDecoration(
                                color: selected ? color.primary : color.surface,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: isPastYear ? color.outline.withValues(alpha: .3) : Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _toPersianNumbers(year.toString()),
                                  style: TextStyle(
                                    color: selected ? color.surface :
                                    isPastYear ? color.outline.withValues(alpha: .5) : color.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
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

            if (_showYearSelector) SizedBox(width: 5),
            if (_showYearSelector) VerticalDivider(width: 1, color: color.outlineVariant),
            if (_showYearSelector) SizedBox(width: 10),

            // Calendar panel
            Expanded(
              child: Column(
                children: [
                  Row(
                    spacing: 5,
                    children: [
                      Icon(Icons.calendar_month_rounded, color: color.outline),
                      Text(_formatSelectedDate(_pendingSelection ?? _selectedDate),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color.outline)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Month navigation
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => _showYearSelector = !_showYearSelector);
                            if (_showYearSelector) _scrollToSelectedYear();
                          },
                          child: Text(
                            '${_getAfghanMonthName(_currentMonth.month)} | ${_toPersianNumbers(_selectedYear.toString())}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.primary),
                          ),
                        ),
                      ),

                      // Previous month button - disable if past dates are disabled and we're at the earliest allowed month
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: () {
                          if (widget.disablePastDates) {
                            final prevMonth = Jalali(_currentMonth.year, _currentMonth.month - 1, 1);
                            if (prevMonth.year < _today.year ||
                                (prevMonth.year == _today.year && prevMonth.month < _today.month)) {
                              return;
                            }
                          }
                          _navigateMonth(-1);
                        },
                        iconSize: 20,
                      ),

                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: () => _navigateMonth(1),
                        iconSize: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Weekdays row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekdays.map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color.primary))))).toList(),
                  ),
                  const SizedBox(height: 6),

                  // Calendar grid
                  Expanded(
                    child: GridView.builder(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                      ),
                      itemCount: 42,
                      itemBuilder: (context, index) {
                        final dayOffset = index - ((firstWeekdayOfMonth - 1) % 7);
                        final isCurrentMonthDay = dayOffset >= 0 && dayOffset < monthLength;
                        final day = isCurrentMonthDay ? dayOffset + 1 : null;
                        final date = isCurrentMonthDay ? Jalali(_currentMonth.year, _currentMonth.month, day!) : null;
                        final isSelected = date != null && (_pendingSelection != null ? _isSameDate(date, _pendingSelection!) : _isSameDate(date, _selectedDate));
                        final isToday = date != null && _isSameDate(date, _today);
                        final isDisabled = date != null && _isDateDisabled(date);

                        return InkWell(
                          onTap: (date != null && !isDisabled) ? () => _onDateTapped(date) : null,
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isSelected ? color.primary :
                              isToday ? color.primary.withValues(alpha: .2) :
                              isDisabled ? color.surface.withValues(alpha: .3) : null,
                              shape: BoxShape.circle,
                              border: isToday ? Border.all(color: color.primary, width: 1) : null,
                            ),
                            child: Center(
                              child: Text(
                                day != null ? _toPersianNumbers(day.toString()) : '',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isSelected ? color.surface :
                                  isToday ? color.primary :
                                  isDisabled ? color.outline.withValues(alpha: .5) : color.secondary,
                                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 5),
                  // Footer buttons
                  Row(
                    children: [
                      ZOutlineButton(
                          width: 90,
                          height: 30,
                          onPressed: _selectToday,
                          label: Text(locale.today)
                      ),
                      const SizedBox(width: 8),
                      ZOutlineButton(
                          height: 30,
                          width: 90,
                          isActive: true,
                          onPressed: _pendingSelection != null ? _confirmSelection : null,
                          label: Text(locale.selectKeyword)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFullWeekdayName(int weekday) {
    const weekdays = {
      1: 'شنبه',
      2: 'یکشنبه',
      3: 'دوشنبه',
      4: 'سه‌شنبه',
      5: 'چهارشنبه',
      6: 'پنجشنبه',
      7: 'جمعه',
    };
    return weekdays[weekday] ?? '';
  }

  String _getAfghanMonthName(int month) {
    const names = {1:'حمل',2:'ثور',3:'جوزا',4:'سرطان',5:'اسد',6:'سنبله',7:'میزان',8:'عقرب',9:'قوس',10:'جدی',11:'دلو',12:'حوت'};
    return names[month] ?? '';
  }
}