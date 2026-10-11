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
import 'package:pulsetrack/screens/activity_log_screen.dart';
import 'package:pulsetrack/screens/profile_screen.dart';
import 'package:pulsetrack/state/app_state.dart';

/// Regression tests for horizontal spacing.
///
/// The screens share a `_gap()` helper written as `SizedBox(height: n)`. A
/// SizedBox with only a height has a width of **zero**, so every `_gap()` used
/// inside a Row silently collapsed and butted two widgets together - which is
/// what made the Activity Log read "Completed2d ago".
///
/// These tests measure the real painted geometry, so they fail on the old helper
/// and pass on a helper that sets both dimensions.
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

const String _message = 'Sarah Lee completed Implement Login Screen';

AppState _state() {
  final DateTime now = DateTime.now();
  final Member sarah = const Member(
    id: 'm0',
    name: 'Sarah Lee',
    role: 'Engineer',
    email: 'sarah@example.com',
  );
  final List<Task> tasks = <Task>[
    Task(
      id: 't1',
      title: 'Implement Login Screen',
      assigneeId: 'm0',
      createdAt: now.subtract(const Duration(days: 3)),
      dueDate: now.add(const Duration(days: 5)),
      priority: Priority.high,
      status: TaskStatus.completed,
    ),
    Task(
      id: 't2',
      title: 'Design System - Sprint 4',
      assigneeId: 'm0',
      createdAt: now.subtract(const Duration(days: 3)),
      dueDate: now.add(const Duration(days: 9)),
      priority: Priority.medium,
    ),
    Task(
      id: 't3',
      title: 'API Auth Endpoint - Review',
      assigneeId: 'm0',
      createdAt: now.subtract(const Duration(days: 3)),
      dueDate: now.add(const Duration(days: 12)),
      priority: Priority.medium,
    ),
    Task(
      id: 't4',
      title: 'Offline sync resolution',
      assigneeId: 'm0',
      createdAt: now.subtract(const Duration(days: 3)),
      dueDate: now.add(const Duration(days: 2)),
      priority: Priority.low,
    ),
  ];

  return AppState(
    members: _FakeMembers(<Member>[sarah]),
    tasks: _FakeTasks(tasks),
    activity: _FakeActivity(<Activity>[
      Activity(
        id: 'a1',
        memberId: 'm0',
        message: _message,
        at: now.subtract(const Duration(days: 2)),
        type: ActivityType.completed,
      ),
    ]),
    settings: _FakeSettings(),
  );
}

Future<void> _pump(WidgetTester tester, AppState state, Widget screen) async {
  tester.view.physicalSize = const Size(1170, 6900);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

/// The horizontal space actually painted between two widgets.
double _gapBetween(WidgetTester tester, Finder left, Finder right) =>
    tester.getTopLeft(right).dx - tester.getTopRight(left).dx;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('Activity Log: the type chip is not welded to the timestamp',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();
    await _pump(tester, state, const ActivityLogScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('2d ago'), findsOneWidget);

    final double gap = _gapBetween(
      tester,
      find.text('Completed'),
      find.text('2d ago'),
    );
    expect(
      gap,
      greaterThanOrEqualTo(6),
      reason: 'chip and timestamp are ${gap.toStringAsFixed(1)}px apart '
          '- reads as "Completed2d ago"',
    );
  });

  testWidgets('Activity Log: the avatar is not welded to the message',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();
    await _pump(tester, state, const ActivityLogScreen());

    final double gap = _gapBetween(
      tester,
      find.byType(CircleAvatar).first,
      find.text(_message),
    );
    expect(gap, greaterThanOrEqualTo(6),
        reason: 'avatar and message are ${gap.toStringAsFixed(1)}px apart');
  });

  testWidgets('Profile: the stat tile icon is not welded to its numbers',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();
    state.currentUser = state.members.first;
    await _pump(tester, state, const ProfileScreen());

    expect(tester.takeException(), isNull);

    final double gap = _gapBetween(
      tester,
      find.byIcon(Icons.list_alt),
      find.text('Tasks assigned'),
    );
    expect(gap, greaterThanOrEqualTo(6),
        reason: 'icon and label are ${gap.toStringAsFixed(1)}px apart');
  });

  testWidgets('Profile: the action row icon is not welded to its label',
      (WidgetTester tester) async {
    final AppState state = _state();
    await state.load();
    state.currentUser = state.members.first;
    await _pump(tester, state, const ProfileScreen());

    final double gap = _gapBetween(
      tester,
      find.byIcon(Icons.tune),
      find.text('SLA Rules'),
    );
    expect(gap, greaterThanOrEqualTo(6),
        reason: 'icon and label are ${gap.toStringAsFixed(1)}px apart');
  });
}
