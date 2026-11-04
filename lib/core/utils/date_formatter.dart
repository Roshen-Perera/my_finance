import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dayMonthYear = DateFormat('dd MMM yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonth = DateFormat('MMM');
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);

    if (aDate == today) {
      return 'Today';
    } else if (aDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return _dayMonthYear.format(date);
  }

  static String formatFullDate(DateTime date) => _dayMonthYear.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatShortMonth(DateTime date) => _shortMonth.format(date);
  static String formatTime(DateTime date) => _time.format(date);
  static String formatIso(DateTime date) => _isoDate.format(date);

  /// Returns [start, end] for a given month considering financial month start day
  static ({DateTime start, DateTime end}) getMonthRange(
    DateTime referenceDate, {
    int startDay = 1,
  }) {
    if (startDay <= 1) {
      final start = DateTime(referenceDate.year, referenceDate.month, 1);
      final nextMonth = DateTime(referenceDate.year, referenceDate.month + 1, 1);
      final end = nextMonth.subtract(const Duration(milliseconds: 1));
      return (start: start, end: end);
    } else {
      DateTime start;
      if (referenceDate.day >= startDay) {
        start = DateTime(referenceDate.year, referenceDate.month, startDay);
      } else {
        start = DateTime(referenceDate.year, referenceDate.month - 1, startDay);
      }
      final end = DateTime(start.year, start.month + 1, startDay).subtract(const Duration(milliseconds: 1));
      return (start: start, end: end);
    }
  }

  /// Returns [start, end] for the current week
  static ({DateTime start, DateTime end}) getWeekRange(DateTime referenceDate) {
    // Week starting Monday
    final monday = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
    return (start: start, end: end);
  }

  /// Returns [start, end] for the current year
  static ({DateTime start, DateTime end}) getYearRange(DateTime referenceDate) {
    final start = DateTime(referenceDate.year, 1, 1);
    final end = DateTime(referenceDate.year + 1, 1, 1).subtract(const Duration(milliseconds: 1));
    return (start: start, end: end);
  }
}
