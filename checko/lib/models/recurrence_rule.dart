import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

// ==================== FREQUENCY ENUM ====================

/// Recurrence frequency type
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  static RecurrenceFrequency fromString(String value) {
    return RecurrenceFrequency.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase().substring(0, e.name.length),
      orElse: () => RecurrenceFrequency.daily,
    );
  }

  String toRRule() {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'DAILY';
      case RecurrenceFrequency.weekly:
        return 'WEEKLY';
      case RecurrenceFrequency.monthly:
        return 'MONTHLY';
      case RecurrenceFrequency.yearly:
        return 'YEARLY';
    }
  }
}

// ==================== RECURRENCE END ====================

/// How recurrence ends
class RecurrenceEnd {
  /// End after a specific number of occurrences
  final int? count;

  /// End on a specific date
  final DateTime? date;

  RecurrenceEnd({this.count, this.date})
      : assert(count != null || date != null, 'Either count or date must be provided'),
        assert(count == null || date == null, 'Only one of count or date can be specified');

  /// Create end by count
  factory RecurrenceEnd.byCount(int count) {
    return RecurrenceEnd(count: count);
  }

  /// Create end by date
  factory RecurrenceEnd.byDate(DateTime date) {
    return RecurrenceEnd(date: date);
  }

  /// Create end that never ends (null)
  static RecurrenceEnd? get never => null;

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'date': date?.toIso8601String(),
    };
  }

  factory RecurrenceEnd.fromMap(Map<String, dynamic>? map) {
    if (map == null) return RecurrenceEnd.byCount(1); // Default
    return RecurrenceEnd(
      count: map['count'] as int?,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
    );
  }

  String toRRule() {
    if (count != null) {
      return 'COUNT=$count';
    } else if (date != null) {
      return 'UNTIL=${_formatDateForRRule(date!)}';
    }
    return '';
  }

  static String _formatDateForRRule(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}Z';
  }
}

// ==================== MAIN RECURRENCE RULE ====================

/// Advanced recurrence rule supporting iCalendar RRULE format
///
/// Based on RFC 5545: https://tools.ietf.org/html/rfc5545
///
/// Examples:
/// - Daily: FREQ=DAILY;INTERVAL=1
/// - Weekly on Mon/Wed/Fri: FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR
/// - Monthly on 15th: FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=15
/// - Yearly on birthday: FREQ=YEARLY;INTERVAL=1;BYMONTHDAY=20;BYMONTH=5
class RecurrenceRule {
  /// Frequency of recurrence (daily, weekly, monthly, yearly)
  final RecurrenceFrequency frequency;

  /// Interval between occurrences (default: 1)
  /// e.g., 2 = every 2 days/weeks/months
  final int interval;

  /// End condition for recurrence
  final RecurrenceEnd? end;

  /// Days of week for weekly recurrence (1=Mon, 7=Sun)
  /// Only used when frequency is WEEKLY
  final List<int>? byDay;

  /// Days of month for monthly recurrence (1-31)
  /// Only used when frequency is MONTHLY
  final List<int>? byMonthDay;

  /// Months for yearly recurrence (1-12)
  /// Only used when frequency is YEARLY
  final List<int>? byMonth;

  /// Ordinal position for monthly/yearly (1=first, 2=second, -1=last)
  /// Used with byDay for things like "first Monday"
  final List<int>? bySetPos;

  /// Start date of the recurrence (when the series begins)
  final DateTime? startDate;

  /// Timezone for all-day events (null for local time)
  final String? timezone;

  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.end,
    this.byDay,
    this.byMonthDay,
    this.byMonth,
    this.bySetPos,
    this.startDate,
    this.timezone,
  }) : assert(interval > 0, 'Interval must be positive');

  /// Check if recurrence is infinite (no end)
  bool get isInfinite => end == null;

  /// Check if recurrence ends by count
  bool get endsByCount => end?.count != null;

  /// Check if recurrence ends by date
  bool get endsByDate => end?.date != null;

  /// Generate occurrences within a date range
  List<DateTime> generateOccurrences({
    required DateTime start,
    required DateTime rangeEnd,
    DateTime? rangeStart,
  }) {
    final occurrences = <DateTime>[];
    rangeStart ??= start;

    // Normalize dates to handle timezone
    final localStart = _normalizeDate(start);
    final localRangeStart = _normalizeDate(rangeStart!);
    final localRangeEnd = _normalizeDate(rangeEnd);

    // Start from the first occurrence on or after rangeStart
    var current = _findFirstOccurrence(localStart, localRangeStart);

    // Generate occurrences until we hit the end condition
    while (current.isBefore(localRangeEnd) && _shouldContinue(occurrences.length)) {
      if (!current.isBefore(localRangeStart)) {
        occurrences.add(current);
      }
      current = _getNextOccurrence(current);
    }

    return occurrences;
  }

  /// Normalize date to handle timezone
  DateTime _normalizeDate(DateTime date) {
    if (timezone != null) {
      try {
        final location = tz.getLocation(timezone!);
        return tz.TZDateTime.from(date, location);
      } catch (e) {
        // If timezone is invalid, return local date
      }
    }
    return date;
  }

  /// Find the first occurrence on or after the range start
  DateTime _findFirstOccurrence(DateTime startDate, DateTime rangeStart) {
    // Start from the range start or the series start, whichever is later
    var current = rangeStart.isAfter(startDate) ? rangeStart : startDate;

    // For intervals > 1, find the first valid occurrence
    if (interval > 1) {
      final daysDiff = current.difference(startDate).inDays;
      final periods = (daysDiff / _getIntervalDays()).ceil();
      current = startDate.add(Duration(days: periods * _getIntervalDays()));
    }

    return _alignToConstraints(current);
  }

  /// Align date to recurrence constraints (byDay, byMonthDay, etc.)
  DateTime _alignToConstraints(DateTime date) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return date;
      case RecurrenceFrequency.weekly:
        if (byDay != null && byDay!.isNotEmpty) {
          // Find next matching day
          for (int i = 0; i < 7; i++) {
            final candidate = date.add(Duration(days: i));
            if (byDay!.contains(_weekdayToRRule(candidate.weekday))) {
              return candidate;
            }
          }
        }
        return date;
      case RecurrenceFrequency.monthly:
        if (byMonthDay != null && byMonthDay!.isNotEmpty) {
          // Find the next valid day in the month
          final currentDay = date.day;
          final validDays = byMonthDay!.where((d) => d <= _daysInMonth(date)).toList()..sort();
          for (final day in validDays) {
            if (day >= currentDay) {
              return DateTime(date.year, date.month, day);
            }
          }
          // Move to next month if no valid day found
          return DateTime(date.year, date.month + 1, validDays.first);
        }
        return date;
      case RecurrenceFrequency.yearly:
        if (byMonth != null && byMonth!.isNotEmpty) {
          if (!byMonth!.contains(date.month)) {
            // Find next valid month
            for (final month in byMonth!..sort()) {
              if (month > date.month || (month < date.month && date.month < 12)) {
                final year = month <= date.month ? date.year + 1 : date.year;
                return DateTime(year, month, date.day);
              }
            }
          }
        }
        return date;
    }
  }

  /// Get the next occurrence after the current one
  DateTime _getNextOccurrence(DateTime current) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return current.add(Duration(days: interval));
      case RecurrenceFrequency.weekly:
        return current.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        var next = DateTime(current.year, current.month + interval, 1);
        if (byMonthDay != null && byMonthDay!.isNotEmpty) {
          final validDay = byMonthDay!.firstWhere(
            (d) => d <= _daysInMonth(next),
            orElse: () => 1,
          );
          return DateTime(next.year, next.month, validDay);
        }
        return next;
      case RecurrenceFrequency.yearly:
        return DateTime(current.year + interval, current.month, current.day);
    }
  }

  /// Get interval in days for calculations
  int _getIntervalDays() {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return interval;
      case RecurrenceFrequency.weekly:
        return 7 * interval;
      case RecurrenceFrequency.monthly:
        return 30 * interval; // Approximate
      case RecurrenceFrequency.yearly:
        return 365 * interval; // Approximate
    }
  }

  /// Check if we should continue generating occurrences
  bool _shouldContinue(int currentCount) {
    if (end == null) return true; // Infinite
    if (end!.count != null) return currentCount < end!.count!;
    if (end!.date != null) {
      final now = DateTime.now();
      return now.isBefore(end!.date!);
    }
    return true;
  }

  /// Get days in month
  int _daysInMonth(DateTime date) {
    final nextMonth = date.month == 12
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  /// Convert weekday to RRULE format (MO=1, TU=2, ..., SU=7)
  int _weekdayToRRule(int weekday) {
    // DateTime weekday: 1=Monday, 7=Sunday
    return weekday;
  }

  /// Convert RRULE weekday to DateTime weekday
  int _rRuleToWeekday(int rruleDay) {
    return rruleDay;
  }

  /// Convert to RRULE string format
  String toRRule() {
    final parts = ['FREQ=${frequency.toRRule()}', 'INTERVAL=$interval'];

    if (byDay != null && byDay!.isNotEmpty) {
      final days = byDay!.map(_rRuleDayToString).join(',');
      parts.add('BYDAY=$days');
    }

    if (byMonthDay != null && byMonthDay!.isNotEmpty) {
      final days = byMonthDay!.join(',');
      parts.add('BYMONTHDAY=$days');
    }

    if (byMonth != null && byMonth!.isNotEmpty) {
      final months = byMonth!.join(',');
      parts.add('BYMONTH=$months');
    }

    if (bySetPos != null && bySetPos!.isNotEmpty) {
      final positions = bySetPos!.join(',');
      parts.add('BYSETPOS=$positions');
    }

    if (end != null) {
      parts.add(end!.toRRule());
    }

    return parts.join(';');
  }

  /// Convert RRULE day number to string (1=MO, 2=TU, etc.)
  String _rRuleDayToString(int day) {
    const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return days[day - 1];
  }

  /// Convert RRULE day string to number (MO=1, TU=2, etc.)
  static int rRuleDayToNumber(String day) {
    const days = {'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6, 'SU': 7};
    return days[day.toUpperCase()] ?? 1;
  }

  /// Parse from RRULE string
  factory RecurrenceRule.fromRRule(String rrule, {DateTime? startDate}) {
    final parts = rrule.split(';');
    Map<String, String> params = {};

    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        params[keyValue[0]] = keyValue[1];
      }
    }

    final frequency = RecurrenceFrequency.fromString(params['FREQ'] ?? 'DAILY');
    final interval = int.tryParse(params['INTERVAL'] ?? '1') ?? 1;

    RecurrenceEnd? end;
    if (params['COUNT'] != null) {
      end = RecurrenceEnd.byCount(int.parse(params['COUNT']!));
    } else if (params['UNTIL'] != null) {
      // Parse UNTIL date
      final untilStr = params['UNTIL']!;
      DateTime? untilDate;
      try {
        if (untilStr.endsWith('Z')) {
          untilDate = DateTime.parse(untilStr);
        } else {
          untilDate = DateTime.parse('${untilStr}Z');
        }
      } catch (e) {
        untilDate = null;
      }
      if (untilDate != null) {
        end = RecurrenceEnd.byDate(untilDate);
      }
    }

    List<int>? byDay;
    if (params['BYDAY'] != null) {
      byDay = params['BYDAY']!.split(',').map(rRuleDayToNumber).toList();
    }

    List<int>? byMonthDay;
    if (params['BYMONTHDAY'] != null) {
      byMonthDay = params['BYMONTHDAY']!.split(',').map(int.parse).toList();
    }

    List<int>? byMonth;
    if (params['BYMONTH'] != null) {
      byMonth = params['BYMONTH']!.split(',').map(int.parse).toList();
    }

    List<int>? bySetPos;
    if (params['BYSETPOS'] != null) {
      bySetPos = params['BYSETPOS']!.split(',').map(int.parse).toList();
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      end: end,
      byDay: byDay,
      byMonthDay: byMonthDay,
      byMonth: byMonth,
      bySetPos: bySetPos,
      startDate: startDate,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      'end': end?.toMap(),
      'byDay': byDay,
      'byMonthDay': byMonthDay,
      'byMonth': byMonth,
      'bySetPos': bySetPos,
      'startDate': startDate?.toIso8601String(),
      'timezone': timezone,
      'rrule': toRRule(), // Store RRULE for compatibility
    };
  }

  /// Create from map
  factory RecurrenceRule.fromMap(Map<String, dynamic> map) {
    // Try to parse from RRULE first if available
    if (map['rrule'] != null) {
      try {
        return RecurrenceRule.fromRRule(
          map['rrule'] as String,
          startDate: map['startDate'] != null
              ? DateTime.parse(map['startDate'] as String)
              : null,
        );
      } catch (e) {
        // Fall through to individual field parsing
      }
    }

    final frequency = RecurrenceFrequency.fromString(
      map['frequency'] as String? ?? 'DAILY',
    );

    RecurrenceEnd? end;
    if (map['end'] != null) {
      end = RecurrenceEnd.fromMap(map['end'] as Map<String, dynamic>);
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: map['interval'] as int? ?? 1,
      end: end,
      byDay: (map['byDay'] as List<dynamic>?)?.cast<int>(),
      byMonthDay: (map['byMonthDay'] as List<dynamic>?)?.cast<int>(),
      byMonth: (map['byMonth'] as List<dynamic>?)?.cast<int>(),
      bySetPos: (map['bySetPos'] as List<dynamic>?)?.cast<int>(),
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      timezone: map['timezone'] as String?,
    );
  }

  /// Get human-readable description
  String get description {
    final freqText = _getFrequencyText();
    final endText = _getEndText();
    final constraintsText = _getConstraintsText();

    if (constraintsText.isNotEmpty) {
      return '$freqText on $constraintsText$endText';
    }
    return '$freqText$endText';
  }

  String _getFrequencyText() {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrenceFrequency.weekly:
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case RecurrenceFrequency.monthly:
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurrenceFrequency.yearly:
        return interval == 1 ? 'Yearly' : 'Every $interval years';
    }
  }

  String _getEndText() {
    if (end == null) return '';
    if (end!.count != null) {
      return ', ${end!.count} times';
    } else if (end!.date != null) {
      return ' until ${_formatDate(end!.date!)}';
    }
    return '';
  }

  String _getConstraintsText() {
    if (byDay != null && byDay!.isNotEmpty) {
      const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return byDay!.map((d) => days[d]).join(', ');
    }
    if (byMonthDay != null && byMonthDay!.isNotEmpty) {
      return 'day ${byMonthDay!.join(', ')} of the month';
    }
    if (byMonth != null && byMonth!.isNotEmpty) {
      const months = [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return byMonth!.map((m) => months[m]).join(', ');
    }
    return '';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Create a daily recurrence
  factory RecurrenceRule.daily({int interval = 1, RecurrenceEnd? end}) {
    return RecurrenceRule(frequency: RecurrenceFrequency.daily, interval: interval, end: end);
  }

  /// Create a weekly recurrence
  factory RecurrenceRule.weekly({
    int interval = 1,
    List<int>? weekdays,
    RecurrenceEnd? end,
  }) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.weekly,
      interval: interval,
      byDay: weekdays,
      end: end,
    );
  }

  /// Create a monthly recurrence
  factory RecurrenceRule.monthly({
    int interval = 1,
    List<int>? monthDays,
    RecurrenceEnd? end,
  }) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      interval: interval,
      byMonthDay: monthDays,
      end: end,
    );
  }

  /// Create a yearly recurrence
  factory RecurrenceRule.yearly({
    int interval = 1,
    List<int>? months,
    RecurrenceEnd? end,
  }) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.yearly,
      interval: interval,
      byMonth: months,
      end: end,
    );
  }

  @override
  String toString() => toRRule();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurrenceRule &&
        other.frequency == frequency &&
        other.interval == interval &&
        other.end == end &&
        _listEquals(other.byDay, byDay) &&
        _listEquals(other.byMonthDay, byMonthDay) &&
        _listEquals(other.byMonth, byMonth);
  }

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        end,
        byDay,
        byMonthDay,
        byMonth,
      );

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ==================== PRESET RECURRENCES ====================

/// Common recurrence presets
class RecurrencePresets {
  /// Every day
  static RecurrenceRule daily({RecurrenceEnd? end}) {
    return RecurrenceRule.daily(interval: 1, end: end);
  }

  /// Every weekday (Mon-Fri)
  static RecurrenceRule weekdays({RecurrenceEnd? end}) {
    return RecurrenceRule.weekly(
      interval: 1,
      weekdays: [1, 2, 3, 4, 5],
      end: end,
    );
  }

  /// Every week
  static RecurrenceRule weekly({RecurrenceEnd? end}) {
    return RecurrenceRule.weekly(interval: 1, end: end);
  }

  /// Every 2 weeks
  static RecurrenceRule biweekly({RecurrenceEnd? end}) {
    return RecurrenceRule.weekly(interval: 2, end: end);
  }

  /// Every month
  static RecurrenceRule monthly({RecurrenceEnd? end}) {
    return RecurrenceRule.monthly(interval: 1, end: end);
  }

  /// Every year
  static RecurrenceRule yearly({RecurrenceEnd? end}) {
    return RecurrenceRule.yearly(interval: 1, end: end);
  }

  /// Weekends (Sat-Sun)
  static RecurrenceRule weekends({RecurrenceEnd? end}) {
    return RecurrenceRule.weekly(
      interval: 1,
      weekdays: [6, 7],
      end: end,
    );
  }

  /// First Monday of the month
  static RecurrenceRule firstMonday({RecurrenceEnd? end}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      interval: 1,
      byDay: [1],
      bySetPos: [1],
      end: end,
    );
  }

  /// Last Friday of the month
  static RecurrenceRule lastFriday({RecurrenceEnd? end}) {
    return RecurrenceRule(
      frequency: RecurrenceFrequency.monthly,
      interval: 1,
      byDay: [5],
      bySetPos: [-1],
      end: end,
    );
  }
}
