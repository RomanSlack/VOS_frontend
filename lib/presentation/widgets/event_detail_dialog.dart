import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/calendar_models.dart';
import 'package:vos_app/features/calendar/bloc/calendar_bloc.dart';
import 'package:vos_app/features/calendar/bloc/calendar_event.dart';
import 'package:vos_app/presentation/widgets/event_form_dialog.dart';

class EventDetailDialog extends StatelessWidget {
  final CalendarEvent event;

  const EventDetailDialog({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = event.startTime.toLocal();
    final endTime = event.endTime.toLocal();

    return Dialog(
      backgroundColor: const Color(0xFF303030),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF757575)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Time
            _buildInfoRow(
              Icons.access_time,
              'Time',
              event.allDay
                  ? 'All day'
                  : '${DateFormat('MMM dd, yyyy • h:mm a').format(startTime)}\n${DateFormat('MMM dd, yyyy • h:mm a').format(endTime)}',
            ),

            // Location
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.location_on,
                'Location',
                event.location!,
              ),
            ],

            // Description
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.notes,
                'Description',
                event.description!,
              ),
            ],

            // Recurrence
            if (event.isRecurring) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.repeat,
                'Recurrence',
                event.recurrenceRule!.toHumanReadable(),
              ),
            ],

            // Auto-reminders
            if (event.autoReminders != null && event.autoReminders!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.notifications,
                'Reminders',
                event.autoReminders!.map(_formatReminderTime).join(', '),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(color: Color(0xFF424242)),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _deleteEvent(context),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Color(0xFF757575)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => EventFormDialog(event: event),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF757575), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFEDEDED),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatReminderTime(int minutes) {
    if (minutes < 60) return '$minutes min before';
    if (minutes < 1440) return '${minutes ~/ 60} hr before';
    if (minutes < 10080) return '${minutes ~/ 1440} day before';
    return '${minutes ~/ 10080} week before';
  }

  void _deleteEvent(BuildContext context) {
    if (event.isRecurring) {
      // Show options for recurring event
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF303030),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          title: const Text(
            'Delete Recurring Event',
            style: TextStyle(color: Color(0xFFEDEDED)),
          ),
          content: const Text(
            'This is a recurring event. How would you like to delete it?',
            style: TextStyle(color: Color(0xFF757575)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performDelete(context, 'all');
              },
              child: const Text(
                'Delete All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      // Confirm single event deletion
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF303030),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          title: const Text(
            'Delete Event',
            style: TextStyle(color: Color(0xFFEDEDED)),
          ),
          content: const Text(
            'Are you sure you want to delete this event? This action cannot be undone.',
            style: TextStyle(color: Color(0xFF757575)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _performDelete(context, 'all');
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

  void _performDelete(BuildContext context, String deleteMode) {
    final request = DeleteEventRequest(
      eventId: event.id,
      deleteMode: deleteMode,
    );

    context.read<CalendarBloc>().add(DeleteCalendarEvent(request));
    Navigator.pop(context);
  }
}
