import 'dart:js' as js;

/// Web implementation for timezone helper
class TimezoneHelper {
  static String? getUserTimezone() {
    try {
      // Use JavaScript Intl API to get timezone
      final timezone = js.context.callMethod('eval', [
        'Intl.DateTimeFormat().resolvedOptions().timeZone'
      ]);
      return timezone as String?;
    } catch (e) {
      return null;
    }
  }
}
