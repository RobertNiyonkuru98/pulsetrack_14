import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pulsetrack/data/models/activity.dart';
import 'package:pulsetrack/data/models/member.dart';
import 'package:pulsetrack/data/models/sla_settings.dart';
import 'package:pulsetrack/data/models/task.dart';
import 'package:pulsetrack/data/repositories/activity_repository.dart';
import 'package:pulsetrack/data/repositories/member_repository.dart';
import 'package:pulsetrack/data/repositories/settings_repository.dart';
import 'package:pulsetrack/data/repositories/task_repository.dart';
import 'package:pulsetrack/screens/sla_settings_screen.dart';
import 'package:pulsetrack/state/app_state.dart';

/// The SLA Rules screen is the differentiator, so these tests pin the two claims
/// the assignment cares about:
///   1. moving a threshold changes a real task's status (the live preview), and
///   2. saving writes through AppState, which is what makes every other screen's
///      badges follow without a restart.
class _FakeMembers extends MemberRepository {
  @override
  Future<List<Member>> getAll() async => const <Member>[
        Member(id: 'm1', name: 'John Doe', role: 'Project Manager'),
      ];
}

class _FakeTasks extends TaskRepository {
  _FakeTasks(this.items);

  final List<Task> items;

  @override
  Future<List<Task>> getAll() async => items;
}

class _FakeActivity extends ActivityRepository {
  @override
  Future<List<Activity>> getAll({int limit = 100}) async => <Activity>[];
}

class _FakeSettings extends SettingsRepository {
  SlaSettings? lastSaved;

  @override
  Future<SlaSettings> load() async => const SlaSettings();

  @override
  Future<void> save(SlaSettings settings) async => lastSaved = settings;
}

/// A Medium task whose window is 16 days and which has 4 days left: 25% of the
/// window remains, just under the default 30% Medium threshold. So it sits
/// "At Risk" by default and flips to "On Track" the moment Medium drops below
/// 25% - which is exactly the demo.
Task _thresholdSensitiveTask() {
  final DateTime now = DateTime.now();
  return Task(
    id: 't-sweet',
    title: 'Data Migration Script',
    project: 'Backend (Local)',
    assigneeId: 'm1',
    createdAt: now.subtract(const Duration(days: 12)),
    dueDate: now.add(const Duration(days: 4)),
    priority: Priority.medium,
    status: TaskStatus.inProgress,
  );
}

AppState _state(_FakeSettings settings) => AppState(
      members: _FakeMembers(),
      tasks: _FakeTasks(<Task>[
        _thresholdSensitiveTask(),
        // Completed and overdue, to prove the preview skips tasks the threshold
        // cannot move.
        Task(
          id: 't-done',
          title: 'Implement Login Screen',
          assigneeId: 'm1',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          status: TaskStatus.completed,
        ),
        Task(
          id: 't-late',
          title: 'Write Unit Tests',
          assigneeId: 'm1',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          priority: Priority.critical,
        ),
      ]),
      activity: _FakeActivity(),
      settings: settings,
    );

Future<void> _pump(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(1170, 6900);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: SlaSettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('shows one slider per priority and both behaviour switches',
      (WidgetTester tester) async {
    final AppState state = _state(_FakeSettings());
    await state.load();
    await _pump(tester, state);

    expect(tester.takeException(), isNull);
    expect(find.byType(Slider), findsNWidgets(4));
    expect(find.byType(Switch), findsNWidgets(2));

    for (final String tier in <String>['Critical', 'High', 'Medium', 'Low']) {
      expect(find.text(tier), findsOneWidget, reason: 'missing $tier slider');
    }
    expect(find.text('Flag blocked tasks as At Risk'), findsOneWidget);
    expect(find.text('Warn under 24 hours'), findsOneWidget);

    // The defaults, shown as percentages.
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('previews the task the thresholds can actually move',
      (WidgetTester tester) async {
    final AppState state = _state(_FakeSettings());
    await state.load();
    await _pump(tester, state);

    // The sensitive Medium task is picked, not the completed or overdue one.
    expect(find.text('Data Migration Script'), findsOneWidget);
    expect(find.text('Implement Login Screen'), findsNothing);
    expect(find.text('Write Unit Tests'), findsNothing);

    // 25% left vs a 30% threshold -> At Risk.
    expect(find.text('At Risk'), findsOneWidget);
  });

  testWidgets('lowering the Medium threshold flips the previewed task',
      (WidgetTester tester) async {
    final AppState state = _state(_FakeSettings());
    await state.load();
    await _pump(tester, state);

    expect(find.text('At Risk'), findsOneWidget);

    // Sliders are Critical, High, Medium, Low - so index 2 is Medium. Dragging
    // it hard left clamps it to the 5% minimum, below the task's 25% remaining.
    await tester.drag(find.byType(Slider).at(2), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('5%'), findsOneWidget, reason: 'Medium should be at the min');
    expect(find.text('On Track'), findsOneWidget,
        reason: 'the previewed task should no longer be At Risk');
    expect(
      find.textContaining('Saved rules make this At Risk'),
      findsOneWidget,
      reason: 'the preview should call out the change',
    );
  });

  testWidgets('saving writes through AppState and persists to the repository',
      (WidgetTester tester) async {
    final _FakeSettings settings = _FakeSettings();
    final AppState state = _state(settings);
    await state.load();
    await _pump(tester, state);

    // Nothing saved yet, and Save starts disabled because nothing is dirty.
    FilledButton save() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save rules'));
    expect(save().onPressed, isNull);

    await tester.drag(find.byType(Slider).at(2), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(save().onPressed, isNotNull, reason: 'Save should enable once dirty');

    await tester.tap(find.widgetWithText(FilledButton, 'Save rules'));
    await tester.pumpAndSettle();

    // This is the bit the assignment calls the demo moment: AppState now holds
    // the new value, so every screen watching it repaints its badges.
    expect(state.settings.mediumThreshold, lessThan(0.25));
    expect(settings.lastSaved?.mediumThreshold, state.settings.mediumThreshold);
    expect(save().onPressed, isNull, reason: 'Save should disable again once saved');
  });
}
