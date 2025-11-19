import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/calendar_models.dart';
import 'package:vos_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:vos_app/features/calendar/bloc/calendar_event.dart';
import 'package:vos_app/features/calendar/bloc/calendar_state.dart';
import 'package:vos_app/presentation/widgets/event_detail_dialog.dart';
import 'package:vos_app/presentation/widgets/event_form_dialog.dart';

/// Enhanced Calendar App with full backend integration
class CalendarAppNew extends StatefulWidget {
  const CalendarAppNew({super.key});

  @override
  State<CalendarAppNew> createState() => _CalendarAppNewState();
}

class _CalendarAppNewState extends State<CalendarAppNew> {
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  CalendarView _currentView = CalendarView.month;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    // Load events for current month ± 1 month
    final startDate = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    final endDate = DateTime(_focusedMonth.year, _focusedMonth.month + 2, 0);

    context.read<CalendarBloc>().add(
          LoadCalendarEvents(
            startDate: startDate,
            endDate: endDate,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: const Color(0xFF212121),
        child: BlocConsumer<CalendarBloc, CalendarState>(
          listener: (context, state) {
            if (state is CalendarError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is CalendarOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Header with month/year navigation and view switcher
                _buildHeader(state),

                // View content (Month/Week/Day)
                Expanded(
                  child: _buildViewContent(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(CalendarState state) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // View switcher
          _buildViewSwitcher(),
          const SizedBox(width: 8),

          // Navigation buttons
          Row(
            children: [
              _buildNavButton(
                icon: Icons.chevron_left,
                onPressed: _previousPeriod,
              ),
              const SizedBox(width: 8),
              _buildNavButton(
                icon: Icons.today_outlined,
                onPressed: _goToToday,
              ),
              const SizedBox(width: 8),
              _buildNavButton(
                icon: Icons.chevron_right,
                onPressed: _nextPeriod,
              ),
              const SizedBox(width: 8),
              _buildNavButton(
                icon: Icons.add,
                onPressed: () => _showEventDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildViewButton('Month', CalendarView.month),
          _buildViewButton('Week', CalendarView.week),
          _buildViewButton('Day', CalendarView.day),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label, CalendarView view) {
    final isSelected = _currentView == view;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentView = view;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFFEDEDED),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
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

  Widget _buildViewContent(CalendarState state) {
    if (state is CalendarLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
      );
    }

    if (state is CalendarError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Color(0xFFEDEDED)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final events = state is CalendarLoaded ? state.events : <CalendarEvent>[];

    switch (_currentView) {
      case CalendarView.month:
        return _buildMonthView(events);
      case CalendarView.week:
        return _buildWeekView(events);
      case CalendarView.day:
        return _buildDayView(events);
    }
  }

  Widget _buildMonthView(List<CalendarEvent> events) {
    return Column(
      children: [
        _buildDaysOfWeekHeader(),
        Expanded(
          child: _buildMonthGrid(events),
        ),
      ],
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
        children: daysOfWeek
            .map((day) => Expanded(
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
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMonthGrid(List<CalendarEvent> events) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // Get the Monday of the week containing the first day
    final startDate = firstDayOfMonth.subtract(
      Duration(days: (firstDayOfMonth.weekday - 1) % 7),
    );

    // Calculate weeks needed
    final totalDays = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final weeksNeeded = ((totalDays + firstWeekday - 1) / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: List.generate(weeksNeeded, (weekIndex) {
          return Expanded(
            child: Row(
              children: List.generate(7, (dayIndex) {
                final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                return Expanded(
                  child: _buildDayCell(date, events),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, List<CalendarEvent> allEvents) {
    final isCurrentMonth = date.month == _focusedMonth.month;
    final isToday = _isSameDay(date, _currentDate);
    final isSelected = _isSameDay(date, _selectedDate);
    final isPast = date.isBefore(DateTime.now()) && !isToday;

    // Get events for this day
    final dayEvents = allEvents.where((event) {
      final eventDate = event.startTime.toLocal();
      return _isSameDay(eventDate, date);
    }).toList();

    final hasEvents = dayEvents.isNotEmpty;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          if (date.month != _focusedMonth.month) {
            _focusedMonth = DateTime(date.year, date.month);
          }
        });
      },
      onDoubleTap: () {
        setState(() {
          _selectedDate = date;
          _currentView = CalendarView.day;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _getDayCellColor(isSelected, isToday, isCurrentMonth),
          borderRadius: BorderRadius.circular(6),
          border: _getDayCellBorder(isSelected, isToday),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00BCD4).withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: _getDayTextColor(isSelected, isToday, isCurrentMonth, isPast),
                fontSize: 13,
                fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (hasEvents) ...[
              const SizedBox(height: 2),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemCount: dayEvents.length > 3 ? 3 : dayEvents.length,
                  itemBuilder: (context, index) {
                    if (index == 2 && dayEvents.length > 3) {
                      return Text(
                        '+${dayEvents.length - 2} more',
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }
                    return _buildEventIndicator(dayEvents[index]);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventIndicator(CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: _getEventColor(event).withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: _getEventColor(event),
          width: 0.5,
        ),
      ),
      child: Text(
        event.title,
        style: TextStyle(
          color: _getEventColor(event),
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Color _getEventColor(CalendarEvent event) {
    if (event.isRecurring) return const Color(0xFFAB47BC); // Purple for recurring
    if (event.allDay) return const Color(0xFF26A69A); // Teal for all-day
    return const Color(0xFF00BCD4); // Blue for normal events
  }

  Widget _buildWeekView(List<CalendarEvent> events) {
    // Get the start of the week (Monday)
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return Column(
      children: [
        // Week header
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _isSameDay(date, _selectedDate);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00BCD4)
                          : isToday
                              ? const Color(0xFF00BCD4).withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: const Color(0xFF00BCD4))
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF757575),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFEDEDED),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Week events
        Expanded(
          child: _buildTimelineView(events, startOfWeek, 7),
        ),
      ],
    );
  }

  Widget _buildDayView(List<CalendarEvent> events) {
    return Column(
      children: [
        // Day header
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
            style: const TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Day events
        Expanded(
          child: _buildTimelineView(events, _selectedDate, 1),
        ),
      ],
    );
  }

  Widget _buildTimelineView(
    List<CalendarEvent> allEvents,
    DateTime startDate,
    int days,
  ) {
    // Filter events for the date range
    final rangeEvents = allEvents.where((event) {
      final eventDate = event.startTime.toLocal();
      for (int i = 0; i < days; i++) {
        final checkDate = startDate.add(Duration(days: i));
        if (_isSameDay(eventDate, checkDate)) return true;
      }
      return false;
    }).toList();

    if (rangeEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, color: Colors.grey.shade600, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No events for this period',
              style: TextStyle(color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showEventDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rangeEvents.length,
      itemBuilder: (context, index) {
        final event = rangeEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final startTime = event.startTime.toLocal();
    final endTime = event.endTime.toLocal();

    return GestureDetector(
      onTap: () => _showEventDetailsDialog(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF303030),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getEventColor(event),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (event.isRecurring)
                  const Icon(
                    Icons.repeat,
                    color: Color(0xFFAB47BC),
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              event.allDay
                  ? 'All day'
                  : '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}',
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
              ),
            ),
            if (event.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF757575), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    event.location!,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDayCellColor(bool isSelected, bool isToday, bool isCurrentMonth) {
    if (isSelected) return const Color(0xFF00BCD4);
    if (isToday) return const Color(0xFF00BCD4).withOpacity(0.15);
    return Colors.transparent;
  }

  Border? _getDayCellBorder(bool isSelected, bool isToday) {
    if (isToday && !isSelected) {
      return Border.all(
        color: const Color(0xFF00BCD4).withOpacity(0.5),
        width: 1,
      );
    }
    return null;
  }

  Color _getDayTextColor(
    bool isSelected,
    bool isToday,
    bool isCurrentMonth,
    bool isPast,
  ) {
    if (isSelected) return const Color(0xFFEDEDED);
    if (isToday) return const Color(0xFF00BCD4);
    if (!isCurrentMonth) return const Color(0xFF424242);
    if (isPast) return const Color(0xFF757575);
    return const Color(0xFFEDEDED);
  }

  void _previousPeriod() {
    setState(() {
      switch (_currentView) {
        case CalendarView.month:
          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
          break;
        case CalendarView.week:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
          break;
        case CalendarView.day:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
          break;
      }
    });
    _loadEvents();
  }

  void _nextPeriod() {
    setState(() {
      switch (_currentView) {
        case CalendarView.month:
          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
          break;
        case CalendarView.week:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
          break;
        case CalendarView.day:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
          break;
      }
    });
    _loadEvents();
  }

  void _goToToday() {
    setState(() {
      _currentDate = DateTime.now();
      _selectedDate = _currentDate;
      _focusedMonth = _currentDate;
    });
    _loadEvents();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showEventDialog({CalendarEvent? event}) {
    showDialog(
      context: context,
      builder: (context) => EventFormDialog(
        event: event,
        initialDate: _selectedDate,
      ),
    );
  }

  void _showEventDetailsDialog(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => EventDetailDialog(event: event),
    );
  }
}

enum CalendarView {
  month,
  week,
  day,
}
