import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF212121),
      child: Column(
        children: [
          // Header with month/year navigation
          _buildHeader(),

          // Days of week header
          _buildDaysOfWeekHeader(),

          // Calendar grid - flexible to use available space
          Expanded(
            child: _buildCalendarGrid(),
          ),

          // Selected date info at bottom - flexible sizing
          Flexible(
            flex: 0,
            child: _buildSelectedDateInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Month/Year display
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMM dd').format(_selectedDate),
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Navigation buttons
          Row(
            children: [
              _buildNavButton(
                icon: Icons.chevron_left,
                onPressed: _previousMonth,
              ),
              const SizedBox(width: 8),
              _buildNavButton(
                icon: Icons.today_outlined,
                onPressed: _goToToday,
              ),
              const SizedBox(width: 8),
              _buildNavButton(
                icon: Icons.chevron_right,
                onPressed: _nextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: const Color(0xFFEDEDED),
          size: 18,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDaysOfWeekHeader() {
    const daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: daysOfWeek.map((day) => Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: _buildMonthGrid(),
    );
  }

  Widget _buildMonthGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // Get the Monday of the week containing the first day
    final startDate = firstDayOfMonth.subtract(
      Duration(days: (firstDayOfMonth.weekday - 1) % 7),
    );

    // Calculate weeks needed
    final totalDays = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final weeksNeeded = ((totalDays + firstWeekday - 1) / 7).ceil();

    return Column(
      children: List.generate(weeksNeeded, (weekIndex) {
        return Expanded(
          child: Row(
            children: List.generate(7, (dayIndex) {
              final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
              return Expanded(
                child: _buildDayCell(date),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isCurrentMonth = date.month == _focusedMonth.month;
    final isToday = _isSameDay(date, _currentDate);
    final isSelected = _isSameDay(date, _selectedDate);
    final isPast = date.isBefore(DateTime.now()) && !isToday;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          if (date.month != _focusedMonth.month) {
            _focusedMonth = DateTime(date.year, date.month);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _getDayCellColor(isSelected, isToday, isCurrentMonth),
          borderRadius: BorderRadius.circular(6),
          border: _getDayCellBorder(isSelected, isToday),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: _getDayTextColor(isSelected, isToday, isCurrentMonth, isPast),
              fontSize: 13,
              fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Color _getDayCellColor(bool isSelected, bool isToday, bool isCurrentMonth) {
    if (isSelected) {
      return const Color(0xFF2196F3);
    }
    if (isToday) {
      return const Color(0xFF2196F3).withOpacity(0.15);
    }
    if (isCurrentMonth) {
      return Colors.transparent;
    }
    return Colors.transparent;
  }

  Border? _getDayCellBorder(bool isSelected, bool isToday) {
    if (isToday && !isSelected) {
      return Border.all(
        color: const Color(0xFF2196F3).withOpacity(0.5),
        width: 1,
      );
    }
    return null;
  }

  Color _getDayTextColor(bool isSelected, bool isToday, bool isCurrentMonth, bool isPast) {
    if (isSelected) {
      return const Color(0xFFEDEDED);
    }
    if (isToday) {
      return const Color(0xFF2196F3);
    }
    if (!isCurrentMonth) {
      return const Color(0xFF424242);
    }
    if (isPast) {
      return const Color(0xFF757575);
    }
    return const Color(0xFFEDEDED);
  }

  Widget _buildSelectedDateInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Date info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getDateDescription(_selectedDate),
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 10,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              _buildActionButton(
                icon: Icons.event_outlined,
                label: 'Add Event',
                onPressed: () {
                  // TODO: Add event functionality
                  _showAddEventDialog();
                },
              ),
              const SizedBox(width: 6),
              _buildActionButton(
                icon: Icons.view_day_outlined,
                label: 'View Day',
                onPressed: () {
                  // TODO: View day details
                  _showDayDetails();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFFEDEDED),
              size: 12,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentDate = DateTime.now();
      _selectedDate = _currentDate;
      _focusedMonth = _currentDate;
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _getDateDescription(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${difference.abs()} days ago';
    }
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF303030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: Text(
          'Add Event',
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Event creation for ${DateFormat('MMM dd, yyyy').format(_selectedDate)} coming soon!',
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF303030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: Text(
          'Day Details',
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No events scheduled for this day.',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }
}