/// Minimal, dependency-free date/duration formatting — avoids pulling in
/// `intl` for a handful of display strings.
class DateFormatting {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  static String weekdayShortDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

  static String clock(DateTime d) {
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  static String duration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    if (d.inDays < 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inDays}d ${d.inHours % 24}h';
  }

  /// e.g. "in 3 days", "in 6 hours", "ready now"
  static String relativeToNow(DateTime target) {
    final now = DateTime.now();
    if (!target.isAfter(now)) return 'Ready now';
    final diff = target.difference(now);
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'in ${diff.inHours} hr';
    return 'in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
