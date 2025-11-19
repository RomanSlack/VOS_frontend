import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vos_app/core/models/calendar_models.dart';

/// Notification toast widget for displaying triggered reminders
class NotificationToast extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onDismiss;

  const NotificationToast({
    super.key,
    required this.reminder,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00BCD4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Color(0xFF00BCD4),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Reminder',
                      style: TextStyle(
                        color: Color(0xFFEDEDED),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF757575), size: 18),
                    onPressed: onDismiss,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                reminder.title,
                style: const TextStyle(
                  color: Color(0xFFEDEDED),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Time
              const SizedBox(height: 4),
              Text(
                DateFormat('h:mm a').format(reminder.triggerTime.toLocal()),
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                ),
              ),

              // Description
              if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reminder.description!,
                  style: const TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Event info if event-attached
              if (reminder.isEventAttached && reminder.eventTitle != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF424242),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: Color(0xFF00BCD4), size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Event: ${reminder.eventTitle}',
                          style: const TextStyle(
                            color: Color(0xFF00BCD4),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay manager for showing notification toasts
class NotificationToastManager {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    Reminder reminder, {
    Duration duration = const Duration(seconds: 30),
    VoidCallback? onDismiss,
  }) {
    // Dismiss any existing toast
    dismiss();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20,
        right: 20,
        child: NotificationToast(
          reminder: reminder,
          onDismiss: () {
            dismiss();
            onDismiss?.call();
          },
        ),
      ),
    );

    overlay.insert(entry);
    _currentEntry = entry;

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (_currentEntry == entry) {
        dismiss();
        onDismiss?.call();
      }
    });
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
