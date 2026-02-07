import '../models/event.dart';
import 'package:flutter/material.dart';

/// Conflict severity level
enum ConflictSeverity {
  minor,    // < 15 minutes overlap
  moderate, // 15-60 minutes overlap
  severe,   // > 60 minutes overlap
}

/// Event conflict information
class EventConflict {
  final Event event1;
  final Event event2;
  final Duration overlapDuration;
  final ConflictSeverity severity;

  EventConflict({
    required this.event1,
    required this.event2,
    required this.overlapDuration,
    required this.severity,
  });

  @override
  String toString() {
    return 'Conflict between ${event1.title} and ${event2.title}: '
        '${overlapDuration.inMinutes} min (${severity.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventConflict &&
        other.event1.id == event1.id &&
        other.event2.id == event2.id;
  }

  @override
  int get hashCode => Object.hash(event1.id, event2.id);
}

/// Time slot suggestion for rescheduling
class TimeSlotSuggestion {
  final DateTime startTime;
  final DateTime endTime;
  final double score;
  final String? reason;

  TimeSlotSuggestion({
    required this.startTime,
    required this.endTime,
    required this.score,
    this.reason,
  });

  /// Get duration of the suggested slot
  Duration get duration => endTime.difference(startTime);

  /// Get formatted time range
  String get timeRange {
    final startFormat = startTime.hour == 0 && startTime.minute == 0
        ? '12 AM'
        : startTime.hour == 12
            ? '12 PM'
            : '${startTime.hour > 12 ? startTime.hour - 12 : startTime.hour}'
                '${startTime.minute > 0 ? ':${startTime.minute.toString().padLeft(2, '0')}' : ''}'
                '${startTime.hour >= 12 ? ' PM' : ' AM'}';

    final endFormat = endTime.hour == 0 && endTime.minute == 0
        ? '12 AM'
        : endTime.hour == 12
            ? '12 PM'
            : '${endTime.hour > 12 ? endTime.hour - 12 : endTime.hour}'
                '${endTime.minute > 0 ? ':${endTime.minute.toString().padLeft(2, '0')}' : ''}'
                '${endTime.hour >= 12 ? ' PM' : ' AM'}';

    return '$startFormat - $endFormat';
  }

  @override
  String toString() => '$timeRange (score: $score)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlotSuggestion &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => Object.hash(startTime, endTime);
}

/// Date range for searching
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end})
      : assert(end.isAfter(start), 'End must be after start');

  /// Get duration of the range
  Duration get duration => end.difference(start);

  /// Check if a date/time is within this range
  bool contains(DateTime date) {
    return !date.isBefore(start) && date.isBefore(end);
  }
}

/// Service for detecting and resolving event conflicts
class ConflictDetectionService {
  // ==================== CONFLICT DETECTION ====================

  /// Detect all overlapping events
  static List<EventConflict> detectConflicts(List<Event> events) {
    if (events.length < 2) return [];

    final conflicts = <EventConflict>[];

    // Sort events by start time
    final sorted = List<Event>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Check each event against subsequent events
    for (int i = 0; i < sorted.length; i++) {
      for (int j = i + 1; j < sorted.length; j++) {
        final event1 = sorted[i];
        final event2 = sorted[j];

        // Stop checking if event2 starts after event1 ends
        if (event2.startTime.isAfter(event1.endTime)) {
          break;
        }

        // Skip if both events are transparent
        if (event1.transparency == EventTransparency.transparent &&
            event2.transparency == EventTransparency.transparent) {
          continue;
        }

        // Calculate overlap
        final overlapStart = event2.startTime.isAfter(event1.startTime)
            ? event2.startTime
            : event1.startTime;
        final overlapEnd = event1.endTime.isBefore(event2.endTime)
            ? event1.endTime
            : event2.endTime;

        final overlapDuration = overlapEnd.difference(overlapStart);

        // Only count significant overlaps (> 5 minutes)
        if (overlapDuration.inMinutes > 5) {
          conflicts.add(EventConflict(
            event1: event1,
            event2: event2,
            overlapDuration: overlapDuration,
            severity: _calculateSeverity(overlapDuration),
          ));
        }
      }
    }

    return conflicts;
  }

  /// Detect conflicts for a specific event against existing events
  static List<EventConflict> detectConflictsForEvent(
    Event event,
    List<Event> existingEvents,
  ) {
    return detectConflicts([event, ...existingEvents])
        .where((conflict) => conflict.event1.id == event.id ||
                           conflict.event2.id == event.id)
        .toList();
  }

  /// Calculate conflict severity based on overlap duration
  static ConflictSeverity _calculateSeverity(Duration overlap) {
    final minutes = overlap.inMinutes;

    if (minutes >= 60) return ConflictSeverity.severe;
    if (minutes >= 30) return ConflictSeverity.moderate;
    return ConflictSeverity.minor;
  }

  // ==================== SUGGESTION ENGINE ====================

  /// Suggest alternative time slots for an event
  static List<TimeSlotSuggestion> suggestAlternatives(
    Event event,
    List<Event> existingEvents, {
    DateTimeRange? searchRange,
    int maxSuggestions = 5,
    Duration? searchIncrement,
  }) {
    // Default search range: today to 7 days from now
    final now = DateTime.now();
    final range = searchRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day + 7),
        );

    final duration = event.duration;
    final suggestions = <TimeSlotSuggestion>[];

    // Search for free slots
    var currentTime = range.start;
    final increment = searchIncrement ?? const Duration(minutes: 30);

    // Limit search to prevent infinite loops
    final maxIterations = 1000;
    var iterations = 0;

    while (currentTime.isBefore(range.end) && iterations < maxIterations) {
      final slotEnd = currentTime.add(duration);

      // Check if slot is within range
      if (slotEnd.isAfter(range.end)) {
        break;
      }

      // Check if this slot is free
      final hasConflict = _hasConflictAtTime(
        currentTime,
        slotEnd,
        existingEvents,
        excludeEventId: event.id,
      );

      if (!hasConflict) {
        final score = _scoreTimeSlot(currentTime);
        final reason = _getReasonForScore(score);

        suggestions.add(TimeSlotSuggestion(
          startTime: currentTime,
          endTime: slotEnd,
          score: score,
          reason: reason,
        ));

        // Sort by score and keep only top suggestions
        suggestions.sort((a, b) => b.score.compareTo(a.score));
        if (suggestions.length > maxSuggestions) {
          suggestions.removeRange(maxSuggestions, suggestions.length);
        }
      }

      currentTime = currentTime.add(increment);
      iterations++;
    }

    return suggestions;
  }

  /// Check if there's a conflict at the given time
  static bool _hasConflictAtTime(
    DateTime startTime,
    DateTime endTime,
    List<Event> events, {
    String? excludeEventId,
  }) {
    for (final event in events) {
      // Skip the event we're checking for
      if (excludeEventId != null && event.id == excludeEventId) {
        continue;
      }

      // Skip transparent events
      if (event.transparency == EventTransparency.transparent) {
        continue;
      }

      // Check for overlap
      final overlaps = startTime.isBefore(event.endTime) &&
          endTime.isAfter(event.startTime);

      if (overlaps) {
        return true;
      }
    }

    return false;
  }

  /// Score a time slot based on various factors
  static double _scoreTimeSlot(DateTime time) {
    double score = 0;

    final hour = time.hour;
    final weekday = time.weekday; // 1 = Monday, 7 = Sunday

    // Business hours preference (9 AM - 5 PM)
    if (hour >= 9 && hour < 17) {
      score += 50;
    } else if (hour >= 7 && hour < 21) {
      score += 30; // Extended hours
    } else {
      score += 10; // Early morning or late evening
    }

    // Weekday preference
    if (weekday <= 5) {
      score += 30; // Monday - Friday
    } else {
      score += 10; // Weekend
    }

    // Morning preference (before noon)
    if (hour < 12) {
      score += 10;
    }

    // Avoid lunch time (12 - 1 PM)
    if (hour == 12) {
      score -= 20;
    }

    // Avoid very early (before 7 AM) or very late (after 9 PM)
    if (hour < 7 || hour >= 21) {
      score -= 10;
    }

    // Round hours preferred
    if (time.minute == 0 || time.minute == 30) {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  /// Get a human-readable reason for the score
  static String? _getReasonForScore(double score) {
    if (score >= 80) return 'Excellent - During business hours';
    if (score >= 60) return 'Good - Reasonable time';
    if (score >= 40) return 'Fair - Early or late';
    if (score >= 20) return 'Less ideal - Outside normal hours';
    return null;
  }

  // ==================== CONFLICT RESOLUTION ====================

  /// Find the best time to reschedule an event to avoid conflicts
  static TimeSlotSuggestion? findBestRescheduleTime(
    Event event,
    List<Event> existingEvents, {
    DateTimeRange? searchRange,
  }) {
    final suggestions = suggestAlternatives(
      event,
      existingEvents,
      searchRange: searchRange,
      maxSuggestions: 10,
    );

    if (suggestions.isEmpty) return null;

    // Return the highest scored suggestion
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.first;
  }

  /// Automatically reschedule an event to the best available slot
  static Event? autoReschedule(
    Event event,
    List<Event> existingEvents, {
    DateTimeRange? searchRange,
  }) {
    final suggestion = findBestRescheduleTime(
      event,
      existingEvents,
      searchRange: searchRange,
    );

    if (suggestion == null) return null;

    return event.copyWith(
      startTime: suggestion.startTime,
      endTime: suggestion.endTime,
      modifiedAt: DateTime.now(),
    );
  }

  // ==================== VISUALIZATION HELPERS ====================

  /// Get color for conflict severity
  static Color getSeverityColor(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.minor:
        return const Color(0xFFFBBF24); // Yellow
      case ConflictSeverity.moderate:
        return const Color(0xFFF97316); // Orange
      case ConflictSeverity.severe:
        return const Color(0xFFEF4444); // Red
    }
  }

  /// Get conflict icon
  static IconData getSeverityIcon(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.minor:
        return Icons.info_outline;
      case ConflictSeverity.moderate:
        return Icons.warning_amber;
      case ConflictSeverity.severe:
        return Icons.error;
    }
  }

  /// Get user-friendly message for conflict
  static String getConflictMessage(EventConflict conflict) {
    final duration = conflict.overlapDuration.inMinutes;

    if (duration < 15) {
      return '${conflict.event1.title} overlaps with ${conflict.event2.title} '
          'by a few minutes';
    } else if (duration < 60) {
      return '${conflict.event1.title} conflicts with ${conflict.event2.title} '
          'for ${duration} minutes';
    } else {
      final hours = duration ~/ 60;
      final mins = duration % 60;
      final durationStr = mins > 0 ? '$hours hours $mins mins' : '$hours hours';
      return '${conflict.event1.title} has a major conflict with '
          '${conflict.event2.title} ($durationStr)';
    }
  }

  // ==================== BATCH ANALYSIS ====================

  /// Analyze a day's schedule and return conflict report
  static Map<String, dynamic> analyzeDaySchedule(
    List<Event> events,
    DateTime day,
  ) {
    // Filter events for the day
    final dayEvents = events.where((event) {
      return event.startTime.year == day.year &&
          event.startTime.month == day.month &&
          event.startTime.day == day.day;
    }).toList();

    final conflicts = detectConflicts(dayEvents);

    // Calculate statistics
    int totalEvents = dayEvents.length;
    int conflictingEvents = conflicts.map((c) => c.event1.id)
        .toSet()
        .union(conflicts.map((c) => c.event2.id).toSet())
        .length;
    int totalConflictMinutes = conflicts.fold(
      0,
      (sum, c) => sum + c.overlapDuration.inMinutes,
    );

    // Find busiest hour
    final busiestHour = _findBusiestHour(dayEvents);

    // Calculate free time
    final freeTime = _calculateFreeTime(dayEvents, day);

    return {
      'date': day,
      'totalEvents': totalEvents,
      'conflictingEvents': conflictingEvents,
      'totalConflicts': conflicts.length,
      'totalConflictMinutes': totalConflictMinutes,
      'conflicts': conflicts,
      'busiestHour': busiestHour,
      'freeTime': freeTime,
      'hasConflicts': conflicts.isNotEmpty,
    };
  }

  /// Find the hour with the most events
  static Map<String, dynamic>? _findBusiestHour(List<Event> events) {
    if (events.isEmpty) return null;

    final hourCounts = <int, int>{};
    final hourDurations = <int, Duration>{};

    for (final event in events) {
      for (int hour = event.startTime.hour;
          hour < event.endTime.hour;
          hour++) {
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;

        final hourStart = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
          hour,
        );
        final hourEnd = hourStart.add(const Duration(hours: 1));

        // Calculate overlap with this hour
        final overlapStart = event.startTime.isAfter(hourStart)
            ? event.startTime
            : hourStart;
        final overlapEnd = event.endTime.isBefore(hourEnd)
            ? event.endTime
            : hourEnd;

        final duration = overlapEnd.difference(overlapStart);
        hourDurations[hour] = (hourDurations[hour] ?? Duration.zero) + duration;
      }
    }

    if (hourCounts.isEmpty) return null;

    final busiestHour = hourCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return {
      'hour': busiestHour.key,
      'eventCount': busiestHour.value,
      'totalDuration': hourDurations[busiestHour.key],
    };
  }

  /// Calculate free time in a day
  static List<Map<String, dynamic>> _calculateFreeTime(
    List<Event> events,
    DateTime day,
  ) {
    final freeSlots = <Map<String, dynamic>>[];

    // Sort events by start time
    final sorted = List<Event>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Start from beginning of day (6 AM) or first event
    var lastEndTime = DateTime(day.year, day.month, day.day, 6);

    for (final event in sorted) {
      // Check for gap before this event
      if (event.startTime.isAfter(lastEndTime)) {
        final gap = event.startTime.difference(lastEndTime);
        if (gap.inMinutes >= 30) {
          freeSlots.add({
            'start': lastEndTime,
            'end': event.startTime,
            'duration': gap,
          });
        }
      }

      // Update last end time
      if (event.endTime.isAfter(lastEndTime)) {
        lastEndTime = event.endTime;
      }
    }

    // Check for gap after last event until end of day (10 PM)
    final endOfDay = DateTime(day.year, day.month, day.day, 22);
    if (lastEndTime.isBefore(endOfDay)) {
      final gap = endOfDay.difference(lastEndTime);
      if (gap.inMinutes >= 30) {
        freeSlots.add({
          'start': lastEndTime,
          'end': endOfDay,
          'duration': gap,
        });
      }
    }

    return freeSlots;
  }
}
