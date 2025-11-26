enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

class RecurrenceRule {
  final RecurrenceType type;
  final int interval; // Every X days/weeks/months
  final List<int>? daysOfWeek; // 1-7 for weekly recurrence (1 = Monday)
  final int? dayOfMonth; // 1-31 for monthly recurrence
  final DateTime? endDate; // Optional end date for recurrence

  RecurrenceRule({
    this.type = RecurrenceType.none,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
  });

  bool get isRecurring => type != RecurrenceType.none;

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory RecurrenceRule.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return RecurrenceRule();
    }
    return RecurrenceRule(
      type: RecurrenceType.values[map['type'] as int? ?? 0],
      interval: map['interval'] as int? ?? 1,
      daysOfWeek: (map['daysOfWeek'] as List<dynamic>?)?.cast<int>(),
      dayOfMonth: map['dayOfMonth'] as int?,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
    );
  }

  DateTime? getNextOccurrence(DateTime fromDate) {
    if (!isRecurring) return null;

    switch (type) {
      case RecurrenceType.daily:
        return fromDate.add(Duration(days: interval));
      case RecurrenceType.weekly:
        return fromDate.add(Duration(days: 7 * interval));
      case RecurrenceType.monthly:
        return DateTime(
          fromDate.year,
          fromDate.month + interval,
          dayOfMonth ?? fromDate.day,
        );
      case RecurrenceType.yearly:
        return DateTime(
          fromDate.year + interval,
          fromDate.month,
          fromDate.day,
        );
      case RecurrenceType.custom:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          // Find next day of week
          for (int i = 1; i <= 7; i++) {
            final nextDate = fromDate.add(Duration(days: i));
            if (daysOfWeek!.contains(nextDate.weekday)) {
              return nextDate;
            }
          }
        }
        return fromDate.add(Duration(days: interval));
      case RecurrenceType.none:
        return null;
    }
  }

  String get displayText {
    switch (type) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrenceType.weekly:
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case RecurrenceType.monthly:
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurrenceType.yearly:
        return interval == 1 ? 'Yearly' : 'Every $interval years';
      case RecurrenceType.custom:
        if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
          final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final days = daysOfWeek!.map((d) => dayNames[d]).join(', ');
          return 'Every $days';
        }
        return 'Custom';
    }
  }
}

