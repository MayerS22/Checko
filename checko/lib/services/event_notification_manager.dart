import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../database/firestore_service.dart';
import 'notification_service.dart';
import '../theme/app_colors.dart';

/// Manager for event notifications
///
/// Automatically schedules and manages reminders for all events
class EventNotificationManager {
  static final EventNotificationManager _instance =
      EventNotificationManager._internal();
  factory EventNotificationManager() => _instance;
  EventNotificationManager._internal();

  final NotificationService _notifications = NotificationService();
  Timer? _upcomingCheckTimer;

  /// Initialize the notification manager
  Future<void> initialize() async {
    await _notifications.initialize();

    // Start periodic check for upcoming events (every minute)
    _startUpcomingEventCheck();
  }

  /// Schedule reminders for all events
  Future<void> scheduleAllEventReminders() async {
    final events = await FirestoreService.instance.readAllEvents();

    for (final event in events) {
      // Only schedule for future events
      if (event.startTime.isAfter(DateTime.now())) {
        await _notifications.scheduleEventReminders(event);
      }
    }
  }

  /// Schedule reminders for a single event
  Future<void> scheduleEventReminders(Event event) async {
    if (event.reminders.isEmpty) {
      // Add default reminder (15 minutes before) if none set
      final defaultReminder = Event(
        id: event.id,
        title: event.title,
        startTime: event.startTime,
        endTime: event.endTime,
        reminders: [Reminder(minutesBefore: 15)],
      );
      await _notifications.scheduleEventReminders(defaultReminder);
    } else {
      await _notifications.scheduleEventReminders(event);
    }
  }

  /// Handle event creation
  Future<void> onEventCreated(Event event) async {
    await scheduleEventReminders(event);
  }

  /// Handle event update
  Future<void> onEventUpdated(Event event) async {
    // Cancel existing reminders and reschedule
    await _notifications.cancelEventReminders(event.id);
    await scheduleEventReminders(event);
  }

  /// Handle event deletion
  Future<void> onEventDeleted(String eventId) async {
    await _notifications.cancelEventReminders(eventId);
  }

  /// Start periodic check for upcoming events
  void _startUpcomingEventCheck() {
    _upcomingCheckTimer?.cancel();
    _upcomingCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkForUpcomingEvents(),
    );
  }

  /// Check for events starting soon and show notifications
  Future<void> _checkForUpcomingEvents() async {
    try {
      final events = await FirestoreService.instance.readAllEvents();
      final now = DateTime.now();

      for (final event in events) {
        // Check if event is starting in the next 5 minutes
        if (event.startTime.isAfter(now) &&
            event.startTime.isBefore(now.add(const Duration(minutes: 5)))) {
          // Check if we haven't already notified for this event
          // (This could be enhanced with tracking notified events)
          await _notifications.scheduleUpcomingEventNotifications([event]);
        }
      }
    } catch (e) {
      debugPrint('Error checking for upcoming events: $e');
    }
  }

  /// Stop the periodic check
  void stop() {
    _upcomingCheckTimer?.cancel();
    _upcomingCheckTimer = null;
  }

  /// Get all pending notifications
  Future<List<dynamic>> getPendingNotifications() async {
    return await _notifications.getPendingNotifications();
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Check if notifications are permitted
  Future<bool> areNotificationsPermitted() async {
    return await _notifications.areNotificationsEnabled();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return await _notifications.requestPermissions();
  }

  /// Open notification settings
  Future<void> openSettings() async {
    await _notifications.openNotificationSettings();
  }

  /// Dispose of resources
  void dispose() {
    stop();
  }
}

/// Helper class for working with event reminders
class EventReminderHelper {
  /// Get common reminder options
  static List<Reminder> get commonReminders => [
    Reminder(minutesBefore: 0),      // At time of event
    Reminder(minutesBefore: 5),      // 5 minutes before
    Reminder(minutesBefore: 15),     // 15 minutes before
    Reminder(minutesBefore: 30),     // 30 minutes before
    Reminder(minutesBefore: 60),     // 1 hour before
    Reminder(minutesBefore: 120),    // 2 hours before
    Reminder(minutesBefore: 1440),   // 1 day before
  ];

  /// Get display text for a reminder
  static String getReminderText(Reminder reminder) {
    final minutes = reminder.minutesBefore;

    if (minutes == 0) {
      return 'At time of event';
    } else if (minutes < 60) {
      return '$minutes minute${minutes > 1 ? 's' : ''} before';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins > 0) {
        return '$hours hour${hours > 1 ? 's' : ''} $mins minute${mins > 1 ? 's' : ''} before';
      }
      return '$hours hour${hours > 1 ? 's' : ''} before';
    } else {
      final days = minutes ~/ 1440;
      return '$days day${days > 1 ? 's' : ''} before';
    }
  }

  /// Get default reminders based on event duration
  static List<Reminder> getDefaultRemindersForEvent(Event event) {
    final duration = event.duration;

    // For longer events, add more reminders
    if (duration.inHours >= 2) {
      return [
        Reminder(minutesBefore: 1440), // 1 day
        Reminder(minutesBefore: 60),    // 1 hour
        Reminder(minutesBefore: 15),    // 15 minutes
      ];
    } else if (duration.inHours >= 1) {
      return [
        Reminder(minutesBefore: 60),  // 1 hour
        Reminder(minutesBefore: 15),  // 15 minutes
      ];
    } else {
      return [
        Reminder(minutesBefore: 30), // 30 minutes
        Reminder(minutesBefore: 5),  // 5 minutes
      ];
    }
  }

  /// Check if a reminder should be triggered
  static bool shouldTriggerReminder(Event event, Reminder reminder) {
    final reminderTime = event.startTime.subtract(
      Duration(minutes: reminder.minutesBefore),
    );

    // Trigger if reminder time is in the past but event hasn't started yet
    final now = DateTime.now();
    return reminderTime.isBefore(now) && event.startTime.isAfter(now);
  }

  /// Check if a reminder time has passed
  static bool hasReminderTimePassed(Event event, Reminder reminder) {
    final reminderTime = event.startTime.subtract(
      Duration(minutes: reminder.minutesBefore),
    );
    return reminderTime.isBefore(DateTime.now());
  }

  /// Get next reminder time for an event
  static DateTime? getNextReminderTime(Event event) {
    if (event.reminders.isEmpty) return null;

    // Sort reminders by time before (descending)
    final sortedReminders = List<Reminder>.from(event.reminders);
    sortedReminders.sort((a, b) => b.minutesBefore.compareTo(a.minutesBefore));

    final now = DateTime.now();

    // Find the next reminder that hasn't passed yet
    for (final reminder in sortedReminders) {
      final reminderTime = event.startTime.subtract(
        Duration(minutes: reminder.minutesBefore),
      );

      if (reminderTime.isAfter(now)) {
        return reminderTime;
      }
    }

    return null;
  }

  /// Check if any reminders are still pending for an event
  static bool hasPendingReminders(Event event) {
    return getNextReminderTime(event) != null;
  }

  /// Get time until next reminder
  static Duration? getTimeUntilNextReminder(Event event) {
    final nextReminderTime = getNextReminderTime(event);
    if (nextReminderTime == null) return null;

    return nextReminderTime.difference(DateTime.now());
  }

  /// Validate reminder settings
  static String? validateReminderSettings({
    required List<Reminder> reminders,
    required DateTime eventStart,
  }) {
    if (reminders.isEmpty) {
      return null; // Empty reminders is valid (no notifications)
    }

    // Check for duplicate reminder times
    final uniqueTimes = reminders.map((r) => r.minutesBefore).toSet();
    if (uniqueTimes.length != reminders.length) {
      return 'Duplicate reminder times';
    }

    // Check if any reminder time is after the event
    for (final reminder in reminders) {
      final reminderTime = eventStart.subtract(
        Duration(minutes: reminder.minutesBefore),
      );
      if (reminderTime.isAfter(eventStart)) {
        return 'Reminder time cannot be after event start';
      }
    }

    // Check if reminder times are reasonable
    for (final reminder in reminders) {
      if (reminder.minutesBefore < 0) {
        return 'Reminder time must be before event';
      }
      if (reminder.minutesBefore > 43200) { // More than 30 days
        return 'Reminder time too far in advance';
      }
    }

    return null; // Valid
  }

  /// Suggest optimal reminder times based on event type
  static List<Reminder> suggestReminders({
    required Event event,
    bool isAllDay = false,
    bool isImportant = false,
  }) {
    if (isAllDay) {
      return [
        Reminder(minutesBefore: 1440), // 1 day before
        Reminder(minutesBefore: 60),   // 1 hour before (at start of day)
      ];
    }

    if (isImportant) {
      return [
        Reminder(minutesBefore: 1440), // 1 day before
        Reminder(minutesBefore: 120),  // 2 hours before
        Reminder(minutesBefore: 60),   // 1 hour before
        Reminder(minutesBefore: 15),   // 15 minutes before
      ];
    }

    // Default suggestions based on duration
    return getDefaultRemindersForEvent(event);
  }
}

/// Widget for selecting reminder times
class ReminderPicker extends StatefulWidget {
  final List<Reminder> selectedReminders;
  final ValueChanged<List<Reminder>> onChanged;
  final int maxReminders;

  const ReminderPicker({
    super.key,
    required this.selectedReminders,
    required this.onChanged,
    this.maxReminders = 5,
  });

  @override
  State<ReminderPicker> createState() => _ReminderPickerState();
}

class _ReminderPickerState extends State<ReminderPicker> {
  late Set<Reminder> _selectedReminders;

  @override
  void initState() {
    super.initState();
    _selectedReminders = widget.selectedReminders.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Reminders',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EventReminderHelper.commonReminders.map((reminder) {
            final isSelected = _selectedReminders.any(
              (r) => r.minutesBefore == reminder.minutesBefore,
            );
            return FilterChip(
              label: Text(EventReminderHelper.getReminderText(reminder)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (_selectedReminders.length < widget.maxReminders) {
                      _selectedReminders.add(reminder);
                    }
                  } else {
                    _selectedReminders.remove(reminder);
                  }
                  widget.onChanged(_selectedReminders.toList());
                });
              },
              selectedColor: AppColors.accent.withOpacity(0.2),
              checkmarkColor: AppColors.accent,
            );
          }).toList(),
        ),
        if (_selectedReminders.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.textMutedColor,
            ),
          ),
          const SizedBox(height: 8),
          ..._selectedReminders.map((reminder) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      EventReminderHelper.getReminderText(reminder),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _selectedReminders.remove(reminder);
                          widget.onChanged(_selectedReminders.toList());
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
