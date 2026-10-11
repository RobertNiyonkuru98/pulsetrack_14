import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pulsetrack/data/models/activity.dart';
import 'package:pulsetrack/data/models/member.dart';
import 'package:pulsetrack/data/models/sla_settings.dart';
import 'package:pulsetrack/data/models/sla_status.dart';
import 'package:pulsetrack/data/models/task.dart';
import 'package:pulsetrack/data/repositories/activity_repository.dart';
import 'package:pulsetrack/data/repositories/member_repository.dart';
import 'package:pulsetrack/data/repositories/settings_repository.dart';
import 'package:pulsetrack/data/repositories/task_repository.dart';
import 'package:pulsetrack/routes.dart';
import 'package:pulsetrack/screens/insights_screen.dart';
import 'package:pulsetrack/screens/profile_screen.dart';
import 'package:pulsetrack/state/app_state.dart';
import 'package:pulsetrack/widgets/sla_badge.dart';

/// The acceptance criterion for this screen is that its numbers agree with the
/// Dashboard's KPI cards - so these tests build a known project, compute the
/// truth with the engine, and check the screen paints exactly that.
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
  @override
  Future<List<Activity>> getAll({int limit = 100}) async => <Activity>[];
}

class _FakeSettings extends SettingsRepository {
  @override
  Future<SlaSettings> load() async => const SlaSettings();
}

const List<String> _names = <String>[
  'Sarah Lee',
  'Mike Otieno',
  'Alex Kimani',
  'Dana White',
  'Sam Reed',
  'Maya Chen',
];

Task _task({
  required String id,
  required String title,
  required String assigneeId,
  required Priority priority,
  required TaskStatus status,
  required DateTime due,
}) =>
    Task(
      id: id,
      title: title,
      project: 'Mobile Development',
      assigneeId: assigneeId,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: due,
      priority: priority,
      status: status,
    );

/// 12 tasks: 5 On Track, 3 At Risk, 2 Overdue, 2 Completed.
/// Both overdue tasks belong to Sarah (`m0`), so she heads the leaderboard.
List<Task> _seed() {
  final DateTime now = DateTime.now();
  final List<Task> tasks = <Task>[];
  int n = 0;

  for (int i = 0; i < 5; i++) {
    tasks.add(_task(
      id: 'on$i',
      title: 'Refine task list filters ${n++}',
      assigneeId: 'm${1 + i % 5}',
      priority: Priority.medium,
      status: TaskStatus.inProgress,
      due: now.add(Duration(days: 20 + i)),
    ));
  }
  for (int i = 0; i < 3; i++) {
    tasks.add(_task(
      id: 'risk$i',
      title: 'Wire up push notification ${n++}',
      assigneeId: 'm${1 + i}',
      priority: Priority.high,
      status: TaskStatus.inProgress,
      due: now.add(Duration(hours: 3 + i)),
    ));
  }
  for (int i = 0; i < 2; i++) {
    tasks.add(_task(
      id: 'late$i',
      title: 'Implement local storage layer ${n++}',
      assigneeId: 'm0',
      priority: Priority.critical,
      status: TaskStatus.inProgress,
      due: now.subtract(Duration(days: 1 + i)),
    ));
  }
  for (int i = 0; i < 2; i++) {
    tasks.add(_task(
      id: 'done$i',
      title: 'Ship the SLA badge ${n++}',
      assigneeId: 'm${1 + i}',
      priority: Priority.low,
      status: TaskStatus.completed,
      due: now.subtract(Duration(days: 6 + i)),
    ));
  }
  return tasks;
}

AppState _state({List<Task>? tasks}) => AppState(
      members: _FakeMembers(
        List<Member>.generate(
          6,
          (int i) => Member(id: 'm$i', name: _names[i], role: 'Engineer'),
        ),
      ),
      tasks: _FakeTasks(tasks ?? _seed()),
      activity: _FakeActivity(),
      settings: _FakeSettings(),
    );

Future<void> _pump(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(1170, 6900);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: InsightsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('the fixture really is 5/3/2/2 - the truth the screen must match',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();

    expect(state.countOf(SlaStatus.onTrack), 5);
    expect(state.countOf(SlaStatus.atRisk), 3);
    expect(state.countOf(SlaStatus.overdue), 2);
    expect(state.countOf(SlaStatus.completed), 2);
    expect(state.tasks.length, 12);
  });

  testWidgets('renders the three cards with no overflow',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();
    await _pump(tester, state);

    expect(tester.takeException(), isNull);
    expect(find.text('Status breakdown'), findsOneWidget);
    expect(find.text('SLA breach leaderboard'), findsOneWidget);
    expect(find.text('Upcoming deadlines'), findsOneWidget);
  });

  testWidgets('the breakdown shows the same numbers as the Dashboard',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();
    await _pump(tester, state);

    // Header: 12 tasks, and 3 At Risk + 2 Overdue = 5 needing attention.
    expect(find.text('12 tasks  ·  5 need attention'), findsOneWidget);

    // Scope the bar labels to the breakdown card: "At Risk" and "Overdue" also
    // appear as SLA badges in the deadlines card further down the screen.
    final Finder breakdown = find
        .ancestor(
          of: find.text('Status breakdown'),
          matching: find.byType(Container),
        )
        .first;

    for (final String label in <String>[
      'On Track',
      'At Risk',
      'Overdue',
      'Completed',
    ]) {
      expect(
        find.descendant(of: breakdown, matching: find.text(label)),
        findsOneWidget,
        reason: 'missing bar "$label"',
      );
    }

    // The bar values are the engine's counts.
    expect(find.text('5'), findsWidgets); // On Track
    expect(find.text('3'), findsWidgets); // At Risk
    expect(find.text('2'), findsWidgets); // Overdue + Completed
  });

  testWidgets('the leaderboard puts the worst offender first',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();
    await _pump(tester, state);

    // Sarah owns both overdue tasks, so she should be at the top with "2".
    final double sarahY = tester.getTopLeft(find.text('Sarah Lee')).dy;
    for (final String other in <String>[
      'Mike Otieno',
      'Alex Kimani',
      'Dana White',
    ]) {
      expect(tester.getTopLeft(find.text(other)).dy, greaterThan(sarahY),
          reason: '$other should rank below Sarah');
    }
  });

  testWidgets('the leaderboard says so when nobody has breached',
      (WidgetTester tester) async {
    // Same project with the two overdue tasks removed.
    final List<Task> healthy = _seed()
        .where((Task t) => !t.id.startsWith('late'))
        .toList();
    final AppState state = _state(tasks: healthy);
    await state.load();
    await _pump(tester, state);

    expect(state.countOf(SlaStatus.overdue), 0);
    expect(
      find.textContaining('Nobody has breached an SLA'),
      findsOneWidget,
    );
  });

  testWidgets('the deadlines card shows the five soonest open tasks',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();
    await _pump(tester, state);

    // Exactly five, each with its SLA badge. Completed tasks are excluded.
    expect(find.byType(SlaBadge), findsNWidgets(5));
    expect(find.text('Ship the SLA badge 10'), findsNothing);
  });

  testWidgets('an empty project says so instead of drawing empty charts',
      (WidgetTester tester) async {
    final AppState state = _state(tasks: <Task>[]);
    await state.load();
    await _pump(tester, state);

    expect(tester.takeException(), isNull);
    expect(
      find.text('No tasks yet. Create one and the insight appears here.'),
      findsOneWidget,
    );
    expect(find.text('Status breakdown'), findsNothing);
  });

  // Regression guard: rebuilding the Dashboard to match Figma dropped the old
  // "Open Insights" button and left this screen unreachable. The entry point is
  // now a row on Profile, and this test fails if it ever disappears again.
  testWidgets('Profile carries the Insights row, and it opens the screen',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();
    state.currentUser = state.members.first;

    tester.view.physicalSize = const Size(1170, 6900);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          home: const ProfileScreen(),
          routes: <String, WidgetBuilder>{
            Routes.insights: (BuildContext context) => const InsightsScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Insights'), findsOneWidget,
        reason: 'Profile should offer a way in to Insights');
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Status breakdown'), findsOneWidget,
        reason: 'tapping Insights should open the Insights screen');
  });
}
