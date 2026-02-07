import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/todo.dart' as models;
import '../models/event.dart';

/// Notification Service for Checko App
///
/// Features:
/// - Local notifications for tasks and events
/// - Firebase Cloud Messaging (FCM) for push notifications
/// - Scheduled reminders
/// - Task due date notifications
/// - Event start time notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _fcmToken;

  bool get isInitialized => _initialized;
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize local notifications
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Initialize Firebase Cloud Messaging
    await _initializeFCM();

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('FCM Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM Token refreshed: $token');
      });

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Message received: ${message.notification?.title}');
        _showLocalNotificationFromFCM(message);
      });

      // Background message handler (opened app from notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Message opened: ${message.data}');
      });
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to relevant screen based on payload
  }

  /// Show local notification from FCM message
  Future<void> _showLocalNotificationFromFCM(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'checko_channel',
      'Checko Notifications',
      channelDescription: 'Notifications for tasks and events',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.notification?.hashCode ?? 0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  /// Schedule notification for a task
  Future<void> scheduleTaskNotification(models.Todo todo) async {
    if (!todo.isCompleted && todo.dueDate != null) {
      final dueDate = todo.dueDate!;
      final now = DateTime.now();

      // Only schedule if due date is in the future
      if (dueDate.isAfter(now)) {
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'tasks_channel',
          'Task Reminders',
          channelDescription: 'Notifications for task reminders',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

        const DarwinNotificationDetails iOSPlatformChannelSpecifics =
            DarwinNotificationDetails();

        const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );

        // Schedule notification 1 hour before due date
        final scheduledTime = dueDate.subtract(const Duration(hours: 1));

        if (scheduledTime.isAfter(now)) {
          await _localNotifications.zonedSchedule(
            todo.id.hashCode,
            'Task Due Soon',
            '"${todo.title}" is due in 1 hour',
            tz.TZDateTime.from(scheduledTime, tz.local),
            platformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          debugPrint('Scheduled notification for task: ${todo.title}');
        }
      }
    }
  }

  /// Schedule notification for an event
  Future<void> scheduleEventNotification(Event event) async {
    final startTime = event.startTime;
    final now = DateTime.now();

    // Only schedule if start time is in the future
    if (startTime.isAfter(now)) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'events_channel',
        'Event Reminders',
        channelDescription: 'Notifications for event reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Schedule notification 1 day before and 1 hour before
      final oneDayBefore = startTime.subtract(const Duration(days: 1));
      final oneHourBefore = startTime.subtract(const Duration(hours: 1));

      // 1 day before notification
      if (oneDayBefore.isAfter(now)) {
        await _localNotifications.zonedSchedule(
          event.id.hashCode,
          'Event Tomorrow',
          '"${event.title}" starts tomorrow at ${_formatTime(startTime)}',
          tz.TZDateTime.from(oneDayBefore, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('Scheduled 1-day notification for event: ${event.title}');
      }

      // 1 hour before notification
      if (oneHourBefore.isAfter(now)) {
        await _localNotifications.zonedSchedule(
          '${event.id}_hour'.hashCode,
          'Event Starting Soon',
          '"${event.title}" starts in 1 hour',
          tz.TZDateTime.from(oneHourBefore, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('Scheduled 1-hour notification for event: ${event.title}');
      }
    }
  }

  /// Cancel notification for a specific task
  Future<void> cancelTaskNotification(String taskId) async {
    await _localNotifications.cancel(taskId.hashCode);
    debugPrint('Cancelled notification for task: $taskId');
  }

  /// Cancel notification for a specific event
  Future<void> cancelEventNotification(String eventId) async {
    await _localNotifications.cancel(eventId.hashCode);
    await _localNotifications.cancel('${eventId}_hour'.hashCode);
    debugPrint('Cancelled notifications for event: $eventId');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('Cancelled all notifications');
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Show instant notification (for testing)
  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      0,
      'Checko Test',
      'Notifications are working!',
      platformChannelSpecifics,
    );
  }
}
