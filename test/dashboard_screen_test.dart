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
import 'package:pulsetrack/screens/dashboard_screen.dart';
import 'package:pulsetrack/state/app_state.dart';

/// The dashboard is a dense layout, so the thing worth pinning down is that it
/// renders a full project at a real phone size with no overflow, and that the
/// numbers on it are the numbers in the data.
///
/// These fakes stand in for the SQLite repositories, which is the whole point of
/// keeping SQL behind the repository layer - the screen needs no database.
class _FakeMembers extends MemberRepository {
  _FakeMembers(this.items);

  final List<Member> items;

  @override
  Future<List<Member>> getAll() async => items;
}

class _FakeTasks extends TaskRepository {
  _FakeTasks(this.items);

  final List<Task> items;

  @override
  Future<List<Task>> getAll() async => items;
}

class _FakeActivity extends ActivityRepository {
  _FakeActivity(this.items);

  final List<Activity> items;

  @override
  Future<List<Activity>> getAll({int limit = 100}) async =>
      items.take(limit).toList();
}

class _FakeSettings extends SettingsRepository {
  @override
  Future<SlaSettings> load() async => const SlaSettings();
}

Member _member(int i) {
  const List<String> names = <String>[
    'Sarah Lee',
    'Mike Otieno',
    'Alex Kimani',
    'Dana White',
    'Sam Reed',
    'Maya Chen',
  ];
  return Member(id: 'm$i', name: names[i], role: 'Engineer', email: '');
}

Task _task({
  required String id,
  required String title,
  required String assigneeId,
  required Priority priority,
  required TaskStatus status,
  required DateTime due,
  String project = 'Mobile Development',
}) =>
    Task(
      id: id,
      title: title,
      project: project,
      assigneeId: assigneeId,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      dueDate: due,
      priority: priority,
      status: status,
      progress: 0,
    );

List<Task> _seedTasks() {
  final DateTime now = DateTime.now();
  final List<Task> tasks = <Task>[];
  int n = 0;

  // 5 On Track - a comfortable window still remains.
  for (int i = 0; i < 5; i++) {
    tasks.add(_task(
      id: 't${n++}',
      title: 'Refine the task list filters #$i',
      assigneeId: 'm${i % 6}',
      priority: Priority.medium,
      status: TaskStatus.inProgress,
      due: now.add(Duration(days: 20 + i)),
    ));
  }

  // 3 At Risk - under 24 hours left, so the hard safety net fires.
  for (int i = 0; i < 3; i++) {
    tasks.add(_task(
      id: 't${n++}',
      title: 'Wire up push notification #$i',
      assigneeId: 'm${i % 6}',
      priority: Priority.high,
      status: TaskStatus.inProgress,
      due: now.add(Duration(hours: 2 + i)),
    ));
  }

  // 2 Overdue - deadline already passed and still open.
  for (int i = 0; i < 2; i++) {
    tasks.add(_task(
      id: 't${n++}',
      // Deliberately long, to prove the card truncates instead of overflowing.
      title: 'Implement local storage persistence layer for the offline queue #$i',
      assigneeId: 'm${i % 6}',
      priority: Priority.critical,
      status: TaskStatus.inProgress,
      due: now.subtract(Duration(days: 1 + i)),
    ));
  }

  // 2 Completed - completed wins even though the deadline has passed.
  for (int i = 0; i < 2; i++) {
    tasks.add(_task(
      id: 't${n++}',
      title: 'Ship the SLA badge #$i',
      assigneeId: 'm${i % 6}',
      priority: Priority.low,
      status: TaskStatus.completed,
      due: now.subtract(Duration(days: 5 + i)),
    ));
  }

  return tasks;
}

List<Activity> _seedActivity() {
  final DateTime now = DateTime.now();
  return <Activity>[
    Activity(
      id: 'a1',
      memberId: 'm0',
      message: 'Sarah Lee updated UI Design',
      at: now.subtract(const Duration(hours: 2)),
      type: ActivityType.updated,
    ),
    Activity(
      id: 'a2',
      memberId: 'm1',
      message: 'Mike Otieno commented on API Auth Endpoint - Review',
      at: now.subtract(const Duration(hours: 4)),
      type: ActivityType.updated,
    ),
    Activity(
      id: 'a3',
      memberId: 'm2',
      message: 'Alex Kimani closed Bug #104',
      at: now.subtract(const Duration(days: 1)),
      type: ActivityType.completed,
    ),
  ];
}

Future<AppState> _buildState() async {
  final AppState state = AppState(
    members: _FakeMembers(List<Member>.generate(6, _member)),
    tasks: _FakeTasks(_seedTasks()),
    activity: _FakeActivity(_seedActivity()),
    settings: _FakeSettings(),
  );
  await state.load();
  state.currentUser = state.members.first;
  return state;
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  AppState state, {
  // Default is a Pixel-sized canvas - narrower than the design, which is where
  // overflow hides. Pass a taller one when the whole page must be built at once.
  Size physical = const Size(1080, 2340),
  double dpr = 3.0,
}) async {
  tester.view.physicalSize = physical;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // The dashboard never reads prefs itself, but AppState.load() does the
    // "remember who signed in" lookup, so give it an empty store.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('lays out the whole page at phone size with no overflow',
      (WidgetTester tester) async {
    final AppState state = await _buildState();
    await _pumpDashboard(tester, state);

    // A RenderFlex overflow is reported as an exception during pump. This is the
    // assertion that matters most: it is the difference between "compiles" and
    // "paints yellow-and-black stripes on the phone".
    expect(tester.takeException(), isNull);

    // A ListView only builds what is on screen, so walk to the bottom in steps.
    // An overflow anywhere below the fold still throws.
    for (int i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow at scroll step $i',
      );
    }
    expect(find.text('See all'), findsOneWidget);
  });

  testWidgets('renders every Figma section with the real counts',
      (WidgetTester tester) async {
    final AppState state = await _buildState();
    // A viewport tall enough that the lazy ListView builds every section at once,
    // so the labels and numbers can be asserted directly.
    await _pumpDashboard(tester, state, physical: const Size(1170, 6900));

    expect(tester.takeException(), isNull);

    // findsWidgets, not findsOneWidget: a status name legitimately appears more
    // than once on the page (a KPI tile, the donut legend, and possibly the chip).
    for (final String label in <String>[
      'Total Tasks',
      'On Track',
      'At Risk',
      'Overdue',
      'Next Task',
      'PRIORITY 1',
      'Project Health',
      'Health Score',
      'Task Overview',
      'Recent Activity',
      'See all',
    ]) {
      expect(find.text(label), findsWidgets, reason: 'missing "$label"');
    }

    // 5 on track, 3 at risk, 2 overdue, 2 completed, 12 in total.
    expect(find.text('12'), findsWidgets); // total tile + donut centre
    expect(find.text('5'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('2'), findsWidgets);

    expect(find.text('6 Members'), findsOneWidget);
    expect(find.text('Based on the SLA status of 12 tasks'), findsOneWidget);
    expect(find.text('12 active'), findsOneWidget);
  });

  testWidgets('collapses the member avatars into a +N overflow chip',
      (WidgetTester tester) async {
    final AppState state = await _buildState();
    await _pumpDashboard(tester, state);

    // 6 members, 4 avatars shown -> "+2".
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('survives an empty project without throwing',
      (WidgetTester tester) async {
    final AppState state = AppState(
      members: _FakeMembers(<Member>[]),
      tasks: _FakeTasks(<Task>[]),
      activity: _FakeActivity(<Activity>[]),
      settings: _FakeSettings(),
    );
    await state.load();
    await _pumpDashboard(tester, state);

    expect(tester.takeException(), isNull);
    expect(find.text('No members yet'), findsOneWidget);
    expect(
      find.text('You have 0\ntasks due today', findRichText: true),
      findsOneWidget,
    );
  });
}
