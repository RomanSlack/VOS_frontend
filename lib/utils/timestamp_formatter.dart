import 'package:intl/intl.dart';

/// Utility class for formatting timestamps in chat messages
class TimestampFormatter {
  /// Format timestamp for display in message bubbles
  /// - Less than 1 minute: "Just now"
  /// - Less than 1 hour: "5m ago"
  /// - Today (< 6h): "2h ago"
  /// - Today (>= 6h): "14:30"
  /// - Yesterday: "Yesterday at 14:30"
  /// - Within a week: "3 days ago"
  /// - Older: "15/1 14:30"
  static String formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Less than 1 minute: "Just now"
    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    // Less than 1 hour: "5m ago"
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }

    // Today: "2h ago" or show time if > 6h
    if (difference.inDays == 0) {
      if (difference.inHours < 6) {
        return '${difference.inHours}h ago';
      }
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }

    // Yesterday: "Yesterday at 14:30"
    if (difference.inDays == 1) {
      return 'Yesterday at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }

    // Within a week: "3 days ago"
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    // Older: "15/1 14:30"
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Format full timestamp for tooltip
  /// Returns: "Jan 15, 2025 at 2:30 PM"
  static String formatFullTimestamp(DateTime timestamp) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(timestamp);
  }

  /// Format date separator label
  /// - Today: "Today"
  /// - Yesterday: "Yesterday"
  /// - This year: "Jan 15"
  /// - Older: "Jan 15, 2024"
  static String formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    // This year: "Jan 15"
    if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    }

    // Different year: "Jan 15, 2024"
    return DateFormat('MMM d, y').format(date);
  }

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
