import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _shortFormat = DateFormat('MMM dd');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String format(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      return _displayFormat.format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatShort(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString);
      return _shortFormat.format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return _timeFormat.format(dt);
    } catch (_) {
      return '';
    }
  }

  static String relativeDueString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'No due date';
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDate = DateTime(dt.year, dt.month, dt.day);
      final diff = dueDate.difference(today).inDays;

      if (diff < 0) {
        return 'Overdue by ${diff.abs()} ${diff.abs() == 1 ? 'day' : 'days'}';
      } else if (diff == 0) {
        return 'Due today';
      } else if (diff == 1) {
        return 'Due tomorrow';
      } else if (diff <= 7) {
        return 'Due in $diff days';
      } else {
        return 'Due on ${_displayFormat.format(dt)}';
      }
    } catch (_) {
      return isoString;
    }
  }
}
