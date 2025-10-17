import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

class NotificationService {
  static final _logger = Logger('NotificationService');
  static final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      _logger.fine('NotificationService already initialized');
      return;
    }

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      await _createNotificationChannels();

      _isInitialized = true;
      _logger.info('NotificationService initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize NotificationService: $e');
      rethrow;
    }
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel messageChannel = AndroidNotificationChannel(
      'messages',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.high,
    );

    const AndroidNotificationChannel invitesChannel = AndroidNotificationChannel(
      'invites',
      'Invites',
      description: 'Notifications for new invites',
      importance: Importance.high,
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general',
      'General',
      description: 'General notifications',
    );

    final plugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (plugin != null) {
      await plugin.createNotificationChannel(messageChannel);
      await plugin.createNotificationChannel(invitesChannel);
      await plugin.createNotificationChannel(generalChannel);
      _logger.fine('Android notification channels created');
    }
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _logger.info('Notification tapped: ${response.payload}');
  }

  static Future<bool> requestPermissions() async {
    try {
      final NotificationPermission notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();

      if (notificationPermission == NotificationPermission.permanently_denied) {
        _logger.warning('Notification permission permanently denied');
        // TODO: Show UI feedback to user to open device settings, if needed.
        // TODO: UI feedback design needed (good UX to make it not too intrusive)
        return false;
      }
      if (notificationPermission != NotificationPermission.granted) {
        final status = await FlutterForegroundTask.requestNotificationPermission();
        if (status != NotificationPermission.granted) {
          _logger.warning('Notification permission denied');
          return false;
        }
      }

      if (Platform.isAndroid) {
        try {
          if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
            await FlutterForegroundTask.requestIgnoreBatteryOptimization();
          }
          if (!await FlutterForegroundTask.canScheduleExactAlarms) {
            await FlutterForegroundTask.openAlarmsAndRemindersSettings();
          }
        } catch (e) {
          _logger.warning('Failed to configure Android-specific settings: $e');
        }
      }

      return true;
    } catch (e) {
      _logger.severe('Failed to request notification permissions: $e');
      return false;
    }
  }

  static Future<void> showMessageNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? groupKey,
  }) async {
    if (!_isInitialized) {
      _logger.warning('NotificationService not initialized, cannot show notification');
      return;
    }

    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'messages',
        'Messages',
        channelDescription: 'Notifications for new messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        groupKey: groupKey,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      _logger.fine('Message notification shown: $title');
    } catch (e) {
      _logger.severe('Failed to show message notification: $e');
    }
  }

  static Future<void> showInviteNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? groupKey,
  }) async {
    if (!_isInitialized) {
      _logger.warning('NotificationService not initialized, cannot show notification');
      return;
    }
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'invites',
        'Invites',
        channelDescription: 'Notifications for new invites',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        groupKey: groupKey,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      _logger.fine('Invite notification shown: $title');
    } catch (e) {
      _logger.severe('Failed to show invite notification: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      _logger.fine('Notification $id cancelled');
    } catch (e) {
      _logger.severe('Failed to cancel notification $id: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _logger.info('All notifications cancelled');
    } catch (e) {
      _logger.severe('Failed to cancel all notifications: $e');
    }
  }
}
