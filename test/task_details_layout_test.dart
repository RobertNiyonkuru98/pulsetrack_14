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
import 'package:pulsetrack/screens/task_details_screen.dart';
import 'package:pulsetrack/state/app_state.dart';

/// The Due Date / Priority / Status tiles live in a half-width column, so this
/// row is the narrowest space in the app that has to hold a label *and* a
/// control. It overflowed on a real phone ("RIGHT OVERFLOWED BY 16 PIXELS").
///
/// The test drives it with the widest labels the enums can produce - "Critical"
/// for priority and "In Progress" for status - because "High"/"Completed" are
/// not the worst case, and the status tile also carries a PopupMenuButton,
/// which asks for 48px by default.
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

Future<AppState> _buildState(Task task) async {
  final AppState state = AppState(
    members: _FakeMembers(<Member>[
      const Member(
        id: 'm1',
        name: 'Sarah Lee',
        role: 'UI/UX Designer',
        email: '',
      ),
    ]),
    tasks: _FakeTasks(<Task>[task]),
    activity: _FakeActivity(),
    settings: _FakeSettings(),
  );
  await state.load();
  state.currentUser = state.members.first;
  return state;
}

Future<void> _pumpDetails(
  WidgetTester tester,
  AppState state,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: TaskDetailsScreen(taskId: 't1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Task worstCaseTask() => Task(
        id: 't1',
        title: 'Implement Login Screen',
        project: 'UI/UX Design',
        assigneeId: 'm1',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        dueDate: DateTime.now().subtract(const Duration(days: 7)),
        priority: Priority.critical,
        status: TaskStatus.inProgress,
        progress: 50,
      );

  // The screen scrolls, so the tiles are built even when off-screen - which is
  // why an overflow here is catchable without scrolling.
  for (final double width in <double>[360, 412]) {
    testWidgets('the meta tiles lay out with no overflow at ${width.toInt()}pt',
        (WidgetTester tester) async {
      final AppState state = await _buildState(worstCaseTask());
      await _pumpDetails(tester, state, Size(width, 900));

      expect(tester.takeException(), isNull,
          reason: 'the Due Date / Priority / Status row overflowed at '
              '${width.toInt()}pt wide');
    });
  }

  testWidgets('the PARAMETERS tab lays out with no overflow',
      (WidgetTester tester) async {
    final AppState state = await _buildState(worstCaseTask());
    await _pumpDetails(tester, state, const Size(360, 900));
    // Clear anything the Overview tab reported, then switch tabs.
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('PARAMETERS'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'the PARAMETERS tab overflowed at 360pt wide');
  });

  testWidgets('the widest labels really are on screen', (WidgetTester tester) async {
    final AppState state = await _buildState(worstCaseTask());
    await _pumpDetails(tester, state, const Size(412, 900));

    expect(find.text('PRIORITY'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('Critical'), findsWidgets);
    expect(find.text('In Progress'), findsWidgets);
    expect(find.text('DUE DATE'), findsOneWidget);
  });
}
