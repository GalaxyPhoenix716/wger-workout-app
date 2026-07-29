import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:wger/features/routines/providers/gym_state.dart';
import 'package:wger/features/routines/providers/gym_state_notifier.dart';
import 'package:wger/features/routines/widgets/gym_mode/timer.dart';
import 'package:wger/l10n/generated/app_localizations.dart';
import 'package:wger/providers/notification_service_provider.dart';

import '../../../../../test_data/routines.dart';

class FakeNotificationService extends Fake implements NotificationService {
  int? scheduledSeconds;
  bool cancelled = false;

  @override
  Future<void> scheduleRestTimerNotification(int seconds) async {
    scheduledSeconds = seconds;
  }

  @override
  Future<void> cancelRestTimerNotification() async {
    cancelled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeNotificationService fakeNotificationService;
  late PageController pageController;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();

    fakeNotificationService = FakeNotificationService();

    container = ProviderContainer(
      overrides: [
        gymStateProvider.overrideWith(() => GymStateNotifier()),
        notificationServiceProvider.overrideWith((ref) => fakeNotificationService),
      ],
    );

    final routine = getTestRoutine();
    final notifier = container.read(gymStateProvider.notifier);
    notifier.state = GymModeState(
      showExercisePages: true,
      showTimerPages: true,
      useCountdownBetweenSets: true,
      countdownDuration: const Duration(seconds: DEFAULT_COUNTDOWN_DURATION),
      alertOnCountdownEnd: true,
      dayId: routine.days.first.id,
      iteration: 1,
      routine: routine,
    );
    notifier.calculatePages();

    pageController = PageController();
  });

  tearDown(() {
    container.dispose();
    pageController.dispose();
  });

  Future<void> pumpTimerWidget(WidgetTester tester, {int seconds = 0}) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TimerCountdownWidget(pageController, seconds),
          ),
        ),
      ),
    );
  }

  group('TimerCountdownWidget', () {
    testWidgets('schedules notification when countdown starts', (tester) async {
      await pumpTimerWidget(tester, seconds: 90);

      expect(fakeNotificationService.scheduledSeconds, 90);
    });

    testWidgets('cancels notification when disposed', (tester) async {
      await pumpTimerWidget(tester, seconds: 90);

      fakeNotificationService.cancelled = false;

      await tester.pumpWidget(Container());

      expect(fakeNotificationService.cancelled, isTrue);
    });

    testWidgets('renders countdown widget', (tester) async {
      await pumpTimerWidget(tester, seconds: 120);

      expect(find.byType(TimerCountdownWidget), findsOneWidget);
    });

    testWidgets('shows paused text', (tester) async {
      await pumpTimerWidget(tester, seconds: 60);

      expect(find.text('Pause'), findsOneWidget);
    });
  });
}
