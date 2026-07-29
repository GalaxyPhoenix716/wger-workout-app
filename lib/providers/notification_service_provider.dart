import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:wger/core/keys.dart';
import 'package:wger/features/routines/screens/gym_mode.dart';

class NotificationService {
  static const _restTimerNotificationId = 1245;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _initialized = true;
  }

  Future<void> scheduleRestTimerNotification(int secondsFromNow) async {
    if (!_initialized) {
      return;
    }
    await cancelRestTimerNotification();

    final scheduledDate = tz.TZDateTime.from(
      DateTime.now().add(Duration(seconds: secondsFromNow)),
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'rest_timer',
      'Rest Timer',
      channelDescription: 'Notifications for the gym rest timer',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id: _restTimerNotificationId,
      title: 'Rest Timer',
      body: 'Your rest period is over!',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'rest_timer',
    );
  }

  Future<void> cancelRestTimerNotification() async {
    if (!_initialized) {
      return;
    }
    await _plugin.cancel(id: _restTimerNotificationId);
  }

  static void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == 'rest_timer') {
      navigatorKey.currentState?.pushNamed(GymModeScreen.routeName);
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
