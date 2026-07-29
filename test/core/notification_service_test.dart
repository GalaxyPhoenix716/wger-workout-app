import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:wger/providers/notification_service_provider.dart';

import 'notification_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<FlutterLocalNotificationsPlugin>()])
void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late NotificationService service;

  setUp(() {
    tz_data.initializeTimeZones();
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = NotificationService(plugin: mockPlugin);
  });

  group('init', () {
    test('calls plugin.initialize with correct settings', () async {
      await service.init();

      final captured = verify(
        mockPlugin.initialize(
          settings: captureAnyNamed('settings'),
          onDidReceiveNotificationResponse: captureAnyNamed('onDidReceiveNotificationResponse'),
        ),
      ).captured;

      final settings = captured[0] as InitializationSettings;
      expect(settings.android, isA<AndroidInitializationSettings>());
      expect(settings.iOS, isA<DarwinInitializationSettings>());
    });
  });

  group('scheduleRestTimerNotification', () {
    test('cancels any previous notification', () async {
      await service.scheduleRestTimerNotification(60);

      verify(mockPlugin.cancel(id: 1245)).called(1);
    });

    test('schedules after cancel', () async {
      await service.scheduleRestTimerNotification(60);

      verify(
        mockPlugin.zonedSchedule(
          id: 1245,
          title: 'Rest Timer',
          body: 'Your rest period is over!',
          scheduledDate: anyNamed('scheduledDate'),
          notificationDetails: anyNamed('notificationDetails'),
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: 'rest_timer',
        ),
      ).called(1);
    });

    test('scheduled date is approximately now plus given seconds', () async {
      final before = DateTime.now();
      await service.scheduleRestTimerNotification(120);
      final after = DateTime.now();

      final captured = verify(
        mockPlugin.zonedSchedule(
          id: 1245,
          scheduledDate: captureAnyNamed('scheduledDate'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          notificationDetails: anyNamed('notificationDetails'),
          androidScheduleMode: anyNamed('androidScheduleMode'),
          payload: anyNamed('payload'),
        ),
      ).captured;

      final scheduled = captured[0] as DateTime;
      expect(scheduled.difference(before).inSeconds, closeTo(120, 1));
      expect(scheduled.difference(after).inSeconds, closeTo(120, 1));
    });
  });

  group('cancelRestTimerNotification', () {
    test('calls plugin.cancel with the correct id', () async {
      await service.cancelRestTimerNotification();

      verify(mockPlugin.cancel(id: 1245)).called(1);
    });
  });
}
