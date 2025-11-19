import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/calendar_models.dart';
import 'package:vos_app/features/reminders/bloc/reminders_bloc.dart';
import 'package:vos_app/features/reminders/bloc/reminders_event.dart';
import 'package:vos_app/features/reminders/bloc/reminders_state.dart';
import 'package:vos_app/presentation/widgets/reminder_form_dialog.dart';

/// Unified Reminders/Notifications App
/// Displays: standalone reminders, timers, alarms, event-attached, recurring
class RemindersApp extends StatefulWidget {
  const RemindersApp({super.key});

  @override
  State<RemindersApp> createState() => _RemindersAppState();
}

class _RemindersAppState extends State<RemindersApp> {
  ReminderViewMode _viewMode = ReminderViewMode.list;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadReminders() {
    context.read<RemindersBloc>().add(
          LoadReminders(
            startDate: DateTime.now().subtract(const Duration(days: 7)),
            endDate: DateTime.now().add(const Duration(days: 90)),
          ),
        );
  }

  void _startAutoRefresh() {
    // Auto-refresh every 5 seconds for seamless updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        context.read<RemindersBloc>().add(
              SilentRefreshReminders(
                startDate: DateTime.now().subtract(const Duration(days: 7)),
                endDate: DateTime.now().add(const Duration(days: 90)),
              ),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: const Color(0xFF212121),
        child: BlocConsumer<RemindersBloc, RemindersState>(
          listener: (context, state) {
            if (state is RemindersError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is RemindersOperationSuccess) {
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
                // Header
                _buildHeader(state),

                // Content
                Expanded(
                  child: _buildContent(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(RemindersState state) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminders & Notifications',
                  style: TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Timers, alarms, reminders, and event notifications',
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Quick action buttons
          Row(
            children: [
              _buildQuickActionButton(
                icon: Icons.timer,
                label: 'Timer',
                onPressed: () => _showTimerDialog(),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.alarm,
                label: 'Alarm',
                onPressed: () => _showAlarmDialog(),
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: Icons.add,
                label: 'Reminder',
                onPressed: () => _showReminderDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            Icon(icon, color: const Color(0xFF00BCD4), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RemindersState state) {
    if (state is RemindersLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
      );
    }

    if (state is RemindersError) {
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
              onPressed: _loadReminders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Handle both RemindersLoaded and RemindersOperationSuccess
    final reminders = state is RemindersLoaded
        ? state.reminders
        : state is RemindersOperationSuccess
            ? state.reminders
            : <Reminder>[];

    if (reminders.isEmpty) {
      return _buildEmptyState();
    }

    // Use AnimatedSwitcher for smooth transitions between list updates
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _buildRemindersList(
        state is RemindersLoaded ? state : state as RemindersOperationSuccess,
        key: ValueKey(reminders.length), // Key based on list length for smooth updates
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, color: Colors.grey.shade600, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No reminders',
            style: TextStyle(
              color: Color(0xFFEDEDED),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a timer, alarm, or reminder to get started',
            style: TextStyle(color: Color(0xFF757575)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showReminderDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Reminder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList(dynamic state, {Key? key}) {
    // Accept both RemindersLoaded and RemindersOperationSuccess
    final grouped = state is RemindersLoaded
        ? state.groupedReminders
        : (state as RemindersOperationSuccess).reminders.fold<Map<ReminderGroup, List<Reminder>>>(
            {},
            (map, reminder) {
              // Simple grouping logic for operation success state
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final triggerDate = DateTime(
                reminder.triggerTime.year,
                reminder.triggerTime.month,
                reminder.triggerTime.day,
              );

              ReminderGroup group;
              if (reminder.isRecurring) {
                group = ReminderGroup.recurring;
              } else if (triggerDate == today) {
                group = ReminderGroup.today;
              } else {
                group = ReminderGroup.upcoming;
              }

              map[group] = [...(map[group] ?? []), reminder];
              return map;
            },
          );

    final todayReminders = grouped[ReminderGroup.today] ?? [];
    final upcomingReminders = grouped[ReminderGroup.upcoming] ?? [];
    final recurringReminders = grouped[ReminderGroup.recurring] ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today's reminders
        if (todayReminders.isNotEmpty) ...[
          _buildGroupHeader('Today', todayReminders.length),
          const SizedBox(height: 12),
          ...todayReminders.map((reminder) => _buildReminderCard(reminder)),
          const SizedBox(height: 24),
        ],

        // Upcoming reminders
        if (upcomingReminders.isNotEmpty) ...[
          _buildGroupHeader('Upcoming', upcomingReminders.length),
          const SizedBox(height: 12),
          ...upcomingReminders.map((reminder) => _buildReminderCard(reminder)),
          const SizedBox(height: 24),
        ],

        // Recurring reminders
        if (recurringReminders.isNotEmpty) ...[
          _buildGroupHeader('Recurring', recurringReminders.length),
          const SizedBox(height: 12),
          ...recurringReminders.map((reminder) => _buildReminderCard(reminder)),
        ],
      ],
    );
  }

  Widget _buildGroupHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF424242),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final triggerTime = reminder.triggerTime.toLocal();
    final now = DateTime.now();
    final isPast = triggerTime.isBefore(now);

    // Wrap with animated widgets for smooth appearance
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF303030),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getReminderColor(reminder),
            width: 2,
          ),
        ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getReminderColor(reminder).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getReminderIcon(reminder),
              color: _getReminderColor(reminder),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatReminderTime(triggerTime, isPast),
                  style: TextStyle(
                    color: isPast ? Colors.red.shade300 : const Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
                if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.description!,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (reminder.isEventAttached && reminder.eventTitle != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event, color: Color(0xFF00BCD4), size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Event: ${reminder.eventTitle}',
                          style: const TextStyle(
                            color: Color(0xFF00BCD4),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (reminder.isRecurring) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.repeat, color: Color(0xFFAB47BC), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        reminder.recurrenceRule!.toHumanReadable(),
                        style: const TextStyle(
                          color: Color(0xFFAB47BC),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              if (reminder.isEditable)
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF757575), size: 18),
                  onPressed: () => _showEditReminderDialog(reminder),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              if (!reminder.isEditable)
                Tooltip(
                  message: 'Event-attached reminders can only be edited via the event',
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                ),
              const SizedBox(height: 8),
              if (reminder.isEditable)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => _deleteReminder(reminder),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Color _getReminderColor(Reminder reminder) {
    if (reminder.isEventAttached) return const Color(0xFF00BCD4); // Blue
    if (reminder.isRecurring) return const Color(0xFFAB47BC); // Purple
    return const Color(0xFF26A69A); // Teal
  }

  IconData _getReminderIcon(Reminder reminder) {
    if (reminder.isEventAttached) return Icons.event;
    if (reminder.isRecurring) return Icons.repeat;
    // Check if it's likely a timer/alarm based on proximity to now
    final diff = reminder.triggerTime.difference(DateTime.now());
    if (diff.inHours < 24) return Icons.alarm;
    return Icons.notifications;
  }

  String _formatReminderTime(DateTime time, bool isPast) {
    final now = DateTime.now();
    final diff = time.difference(now);

    if (isPast) {
      return 'Overdue - ${DateFormat('MMM dd, h:mm a').format(time)}';
    }

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'In ${diff.inMinutes} minutes';
      }
      return 'Today at ${DateFormat('h:mm a').format(time)}';
    } else if (diff.inDays == 1) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(time)}';
    } else if (diff.inDays < 7) {
      return '${DateFormat('EEEE').format(time)} at ${DateFormat('h:mm a').format(time)}';
    } else {
      return DateFormat('MMM dd, yyyy • h:mm a').format(time);
    }
  }

  void _showTimerDialog() {
    final bloc = context.read<RemindersBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: const ReminderFormDialog(mode: ReminderDialogMode.timer),
      ),
    );
  }

  void _showAlarmDialog() {
    final bloc = context.read<RemindersBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: const ReminderFormDialog(mode: ReminderDialogMode.alarm),
      ),
    );
  }

  void _showReminderDialog() {
    final bloc = context.read<RemindersBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: const ReminderFormDialog(mode: ReminderDialogMode.reminder),
      ),
    );
  }

  void _showEditReminderDialog(Reminder reminder) {
    final bloc = context.read<RemindersBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: ReminderFormDialog(
          mode: ReminderDialogMode.reminder,
          reminder: reminder,
        ),
      ),
    );
  }

  void _deleteReminder(Reminder reminder) {
    final bloc = context.read<RemindersBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF303030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        title: const Text(
          'Delete Reminder',
          style: TextStyle(color: Color(0xFFEDEDED)),
        ),
        content: const Text(
          'Are you sure you want to delete this reminder? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF757575)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              bloc.add(DeleteReminder(reminder.id));
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

enum ReminderViewMode {
  list,
  calendar,
}
