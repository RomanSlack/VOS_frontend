/// Non-web implementation for timezone helper
class TimezoneHelper {
  static String? getUserTimezone() {
    // On mobile/desktop, we don't have access to browser's timezone API
    // Return null and let the backend use its default
    return null;
  }
}
