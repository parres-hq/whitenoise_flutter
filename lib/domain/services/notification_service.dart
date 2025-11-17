import 'dart:convert';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

class NotificationService {
  static final _logger = Logger('NotificationService');
  static final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static GoRouter? _router;

  static Future<void> initialize({FlutterLocalNotificationsPlugin? plugin}) async {
    final notificationPlugin = plugin ?? _flutterLocalNotificationsPlugin;
    if (_isInitialized) {
      _logger.fine('NotificationService already initialized');
      return;
    }

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_notification');

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

      await notificationPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      await _createNotificationChannels(plugin: notificationPlugin);

      _isInitialized = true;
      _logger.info('NotificationService initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize NotificationService: $e');
      rethrow;
    }
  }

  static Future<void> _createNotificationChannels({FlutterLocalNotificationsPlugin? plugin}) async {
    final notificationPlugin = plugin ?? _flutterLocalNotificationsPlugin;
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

    final androidPlugin =
        notificationPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(messageChannel);
      await androidPlugin.createNotificationChannel(invitesChannel);
      await androidPlugin.createNotificationChannel(generalChannel);
      _logger.fine('Android notification channels created');
    }
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload == null || response.payload!.isEmpty) {
      _navigateToChatList();
      return;
    }

    final parsedPayload = parseNotificationPayload(response.payload!);
    if (parsedPayload == null) {
      _navigateToChatList();
      return;
    }

    final groupId = parsedPayload['groupId'] as String?;
    if (groupId == null || groupId.isEmpty) {
      _navigateToChatList();
      return;
    }

    if (_router != null) {
      final notificationType = parsedPayload['type'] as String?;
      final welcomeId = parsedPayload['welcomeId'] as String?;

      if (notificationType == 'invites_sync' && welcomeId != null && welcomeId.isNotEmpty) {
        _router!.go('/chats/$groupId', extra: welcomeId);
        _logger.info('Notification: navigated to chat with invite (groupId: $groupId)');
      } else {
        _router!.go('/chats/$groupId');
        _logger.info('Notification: navigated to chat (groupId: $groupId)');
      }
    } else {
      _logger.warning('Notification: router not initialized');
      _navigateToChatList();
    }
  }

  static void _navigateToChatList() {
    if (_router != null) {
      _router!.go('/chats');
    } else {
      _logger.warning('Notification: cannot navigate - router not initialized');
    }
  }

  static void setRouter(GoRouter router) {
    if (_router != null) {
      return; // Already initialized, avoid redundant calls
    }
    _router = router;
    _logger.fine('Router initialized for notifications');
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
    FlutterLocalNotificationsPlugin? plugin,
    bool? isInitialized,
  }) async {
    final notificationPlugin = plugin ?? _flutterLocalNotificationsPlugin;
    final initialized = isInitialized ?? _isInitialized;
    if (!initialized) {
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
        icon: '@mipmap/ic_notification',
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

      await notificationPlugin.show(
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
    FlutterLocalNotificationsPlugin? plugin,
    bool? isInitialized,
  }) async {
    final notificationPlugin = plugin ?? _flutterLocalNotificationsPlugin;
    final initialized = isInitialized ?? _isInitialized;
    if (!initialized) {
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
        icon: '@mipmap/ic_notification',
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

      await notificationPlugin.show(
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

  static Future<void> cancelNotification(int id, {FlutterLocalNotificationsPlugin? plugin}) async {
    final notificationPlugin = plugin ?? _flutterLocalNotificationsPlugin;
    try {
      await notificationPlugin.cancel(id);
      _logger.fine('Notification $id cancelled');
    } catch (e) {
      _logger.severe('Failed to cancel notification $id: $e');
    }
  }

  /// Platform-independent logic to check if a notification should be cancelled for a given group
  static bool shouldCancelNotificationForGroup(String? payload, String targetGroupId) {
    if (payload == null || payload.isEmpty) {
      return false;
    }

    try {
      final parsedPayload = parseNotificationPayload(payload);
      return parsedPayload != null && parsedPayload['groupId'] == targetGroupId;
    } catch (e) {
      _logger.fine('Failed to parse notification payload for group matching: $e');
      return false;
    }
  }

  /// Platform-independent logic to parse notification payload JSON
  static Map<String, dynamic>? parseNotificationPayload(String payload) {
    if (payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (e) {
      _logger.fine('Failed to parse notification payload JSON: $e');
      return null;
    }
  }

  static Future<void> cancelNotificationsByGroup(
    String groupId, {
    FlutterLocalNotificationsPlugin? plugin,
    bool? isInitialized,
  }) async {
    final notificationPlugin = plugin ?? _flutterLocalNotificationsPlugin;
    final initialized = isInitialized ?? _isInitialized;
    if (!initialized) {
      _logger.warning('NotificationService not initialized, cannot cancel notifications');
      return;
    }

    try {
      // Get all active notifications
      final activeNotifications = await notificationPlugin.getActiveNotifications();

      int cancelledCount = 0;

      for (final notification in activeNotifications) {
        // Use extracted platform-independent logic
        final shouldCancel = shouldCancelNotificationForGroup(notification.payload, groupId);

        final id = notification.id;
        if (shouldCancel && id != null) {
          await notificationPlugin.cancel(id);
          cancelledCount++;
          _logger.fine('Cancelled notification $id for group $groupId');
        }
      }

      _logger.info('Cancelled $cancelledCount notifications for group $groupId');
    } catch (e) {
      _logger.severe('Failed to cancel notifications for group $groupId: $e');
    }
  }

  static Future<void> cancelAllNotifications({FlutterLocalNotificationsPlugin? plugin}) async {
    final notificationPlugin = plugin ?? _flutterLocalNotificationsPlugin;
    try {
      await notificationPlugin.cancelAll();
      _logger.info('All notifications cancelled');
    } catch (e) {
      _logger.severe('Failed to cancel all notifications: $e');
    }
  }
}
