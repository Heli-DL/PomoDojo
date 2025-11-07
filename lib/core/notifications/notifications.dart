import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io' show Platform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static final StreamController<NotificationResponse>
  _actionResponseController = StreamController.broadcast();
  static Stream<NotificationResponse> get onNotificationAction =>
      _actionResponseController.stream;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/app_icon');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          try {
            _actionResponseController.add(response);
          } catch (_) {}
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      await _createNotificationChannels();
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
      _initialized = true;
    }
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    try {
      _actionResponseController.add(response);
    } catch (_) {}
  }

  static Future<void> _createNotificationChannels() async {
    final androidPlugin = AndroidFlutterLocalNotificationsPlugin();

    const sessionCompleteChannel = AndroidNotificationChannel(
      'session_complete',
      'Session Complete',
      description: 'Notifications when focus sessions complete',
      importance: Importance.high,
    );

    const breakOverChannel = AndroidNotificationChannel(
      'break_over',
      'Break Over',
      description: 'Notifications when breaks are over',
      importance: Importance.defaultImportance,
    );

    const streakReminderChannel = AndroidNotificationChannel(
      'streak_reminder',
      'Streak Reminder',
      description: "Reminder to keep your streak alive",
      importance: Importance.high,
    );

    await androidPlugin.createNotificationChannel(sessionCompleteChannel);
    await androidPlugin.createNotificationChannel(breakOverChannel);
    await androidPlugin.createNotificationChannel(streakReminderChannel);
  }

  /// Show immediate notification for session completion
  static Future<void> showSessionComplete() async {
    debugPrint('showSessionComplete called');

    await initialize();

    if (Platform.isAndroid) {
      try {
        final androidImplementation = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidImplementation != null) {
          final granted = await androidImplementation
              .requestNotificationsPermission();
          debugPrint('Notification permission granted: $granted');
          if (granted != true) {
            debugPrint(
              'Notification permission not granted - notification may not show',
            );
          }
        }
      } catch (e) {
        debugPrint('Error requesting notification permission: $e');
      }
    }

    const androidDetails = AndroidNotificationDetails(
      'session_complete',
      'Session Complete',
      channelDescription: 'Notifications for completed focus sessions',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      debugPrint('Attempting to show notification...');
      await _notifications.show(
        1001,
        'Session Complete! 🎉',
        'Great job! Your focus session is complete. Time for a well-deserved break!',
        details,
      );
      debugPrint('Session complete notification shown successfully');
    } catch (e, stackTrace) {
      debugPrint('Failed to show session complete notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Schedule a notification for when the session completes
  static Future<void> scheduleSessionComplete(DateTime completionTime) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'session_complete',
      'Session Complete',
      channelDescription: 'Notifications when focus sessions complete',
      importance: Importance.high,
      icon: 'ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
      styleInformation: BigTextStyleInformation(
        'Great job! Your focus session is complete. Time for a well-deserved break!',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final scheduledTime = tz.TZDateTime.from(completionTime, tz.local);

      await _notifications.zonedSchedule(
        1, // Unique ID for session complete
        'Session Complete! 🎉',
        'Great job! Your focus session is complete. Time for a well-deserved break!',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      debugPrint(
        'Failed to schedule exact notification: ${e.code} - ${e.message}',
      );
      if (e.code == 'exact_alarms_not_permitted') {
        final scheduledTime = tz.TZDateTime.from(completionTime, tz.local);
        await _notifications.zonedSchedule(
          1,
          'Session Complete! 🎉',
          'Great job! Your focus session is complete. Time for a well-deserved break!',
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('Failed to schedule session complete notification: $e');
      rethrow;
    }
  }

  /// Show immediate notification for break completion
  static Future<void> showBreakOver() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'break_over',
      'Break Over',
      channelDescription: 'Notifications when breaks are over',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_notification',
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        2, // Unique ID for break over
        'Break Over! ⏰',
        'Break time is over! Ready to get back to focused work?',
        details,
      );
      // Break over notification shown successfully
    } catch (e) {
      debugPrint('Failed to show break over notification: $e');
      rethrow;
    }
  }

  /// Schedule a notification for when the break is over
  static Future<void> scheduleBreakOver(DateTime breakEndTime) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'break_over',
      'Break Over',
      channelDescription: 'Notifications when breaks are over',
      importance: Importance.defaultImportance,
      icon: 'ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
      styleInformation: BigTextStyleInformation(
        'Break time is over! Ready to get back to focused work?',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final scheduledTime = tz.TZDateTime.from(breakEndTime, tz.local);

      await _notifications.zonedSchedule(
        2, // Unique ID for break over
        'Break Over! ⏰',
        'Break time is over! Ready to get back to focused work?',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      debugPrint(
        'Failed to schedule exact break notification: ${e.code} - ${e.message}',
      );
      if (e.code == 'exact_alarms_not_permitted') {
        final scheduledTime = tz.TZDateTime.from(breakEndTime, tz.local);
        await _notifications.zonedSchedule(
          2,
          'Break Over! ⏰',
          'Break time is over! Ready to get back to focused work?',
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('Failed to schedule break over notification: $e');
      rethrow;
    }
  }

  /// Show immediate streak reminder
  static Future<void> showStreakReminder() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'streak_reminder',
      'Streak Reminder',
      channelDescription: 'Reminder to keep your streak alive',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      3,
      "Don't lose your streak!",
      'Complete at least one session today to keep it going.',
      details,
    );
  }

  /// Schedule streak reminder for a specific time
  static Future<void> scheduleStreakReminder(DateTime remindAt) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'streak_reminder',
      'Streak Reminder',
      channelDescription: 'Reminder to keep your streak alive',
      importance: Importance.high,
      icon: 'ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
      styleInformation: BigTextStyleInformation(
        'Complete at least one session today to keep your streak alive.',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledTime = tz.TZDateTime.from(remindAt, tz.local);
    await _notifications.zonedSchedule(
      3,
      "Don't lose your streak!",
      'Complete at least one session today to keep it going.',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancel streak reminder
  static Future<void> cancelStreakReminder() async {
    await _notifications.cancel(3);
  }

  /// Cancel the session complete notification
  static Future<void> cancelSessionComplete() async {
    await _notifications.cancel(1);
  }

  /// Cancel the break over notification
  static Future<void> cancelBreakOver() async {
    await _notifications.cancel(2);
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static const int _focusShieldNotifId = 10;
  static const String actionPause = 'pause_action';
  static const String actionStop = 'stop_action';
  static const String actionDisableShield = 'disable_shield_action';

  /// Show an ongoing notification while Focus Shield is active with actions
  static Future<void> showFocusShieldOngoing({
    required int minutesRemaining,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'session_complete',
      'Session Complete',
      channelDescription: 'Focus session controls',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      onlyAlertOnce: true,
      showWhen: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(actionPause, 'Pause'),
        AndroidNotificationAction(actionStop, 'Stop'),
        AndroidNotificationAction(actionDisableShield, 'Disable Shield'),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _focusShieldNotifId,
      'Focus Shield active',
      'Remaining ~${minutesRemaining}m • DND enabled',
      details,
    );
  }

  /// Update ongoing Focus Shield notification subtitle
  static Future<void> updateFocusShieldOngoing({
    required int minutesRemaining,
  }) async {
    await showFocusShieldOngoing(minutesRemaining: minutesRemaining);
  }

  /// Cancel ongoing Focus Shield notification
  static Future<void> cancelFocusShieldOngoing() async {
    await _notifications.cancel(_focusShieldNotifId);
  }

  /// Show immediate notification (for testing)
  static Future<void> showTestNotification() async {
    // Showing test notification
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'session_complete',
      'Session Complete',
      channelDescription: 'Test notification',
      importance: Importance.high,
      icon: 'ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        999, // Test ID
        'Test Notification',
        'This is a test notification',
        details,
      );
      // Test notification shown successfully
    } catch (e) {
      debugPrint('Failed to show test notification: $e');
      rethrow;
    }
  }
}
