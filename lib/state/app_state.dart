import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/db_helper.dart';
import '../data/models/activity.dart';
import '../data/models/member.dart';
import '../data/models/sla_settings.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/member_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/task_repository.dart';
import '../logic/health_score.dart';
import '../logic/sla_engine.dart';

/// The one place screens read app data from.
///
/// Screens never touch the database directly. They call AppState, which talks
/// to the repositories and then calls notifyListeners() so every screen using
/// context.watch<AppState>() rebuilds.
class AppState extends ChangeNotifier {
  AppState({
    MemberRepository? members,
    TaskRepository? tasks,
    ActivityRepository? activity,
    SettingsRepository? settings,
    Uuid? uuid,
  })  : _members = members ?? MemberRepository(),
        _tasks = tasks ?? TaskRepository(),
        _activity = activity ?? ActivityRepository(),
        _settings = settings ?? SettingsRepository(),
        _uuid = uuid ?? const Uuid();

  final MemberRepository _members;
  final TaskRepository _tasks;
  final ActivityRepository _activity;
  final SettingsRepository _settings;
  final Uuid _uuid;

  static const String _sessionKey = 'session_member_id';

  bool loading = true;
  List<Member> members = <Member>[];
  List<Task> tasks = <Task>[];
  List<Activity> activity = <Activity>[];
  SlaSettings settings = const SlaSettings();
  Member? currentUser;

  // ------------------------------------------------------------------ loading

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      members = await _members.getAll();
      tasks = await _tasks.getAll();
      activity = await _activity.getAll();
      settings = await _settings.load();

      // Remember who signed in last (this is the only thing we use
      // SharedPreferences for - one small value, not our whole dataset).
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? id = prefs.getString(_sessionKey);
      if (id != null) {
        currentUser = memberById(id);
      }
    } catch (error) {
      debugPrint('AppState.load failed: $error');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    tasks = await _tasks.getAll();
    activity = await _activity.getAll();
    notifyListeners();
  }

  // ------------------------------------------------------------------ derived

  SlaStatus statusOf(Task task) =>
      SlaEngine.evaluate(task, settings: settings);

  String explainStatus(Task task) =>
      SlaEngine.explain(task, settings: settings);

  int get healthScore =>
      HealthScore.compute(tasks, settings: settings);

  int countOf(SlaStatus status) =>
      tasks.where((Task t) => statusOf(t) == status).length;

  Member? memberById(String id) {
    for (final Member m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Overdue and At Risk only, worst first - the "Attention Needed" queue.
  List<Task> get attentionQueue {
    final List<Task> flagged = tasks.where((Task t) {
      final SlaStatus s = statusOf(t);
      return s == SlaStatus.overdue || s == SlaStatus.atRisk;
    }).toList();

    flagged.sort((Task a, Task b) => _urgency(b).compareTo(_urgency(a)));
    return flagged;
  }

  /// Higher number = more urgent. Overdue always outranks At Risk.
  double _urgency(Task task) {
    final SlaStatus status = statusOf(task);
    if (status == SlaStatus.overdue) {
      return 1000 + DateTime.now().difference(task.dueDate).inHours.toDouble();
    }
    final double elapsed = SlaEngine.elapsedPercent(task, DateTime.now());
    double priorityWeight = 1;
    switch (task.priority) {
      case Priority.low:
        priorityWeight = 1;
        break;
      case Priority.medium:
        priorityWeight = 2;
        break;
      case Priority.high:
        priorityWeight = 3;
        break;
      case Priority.critical:
        priorityWeight = 4;
        break;
    }
    return 500 + elapsed * 100 + priorityWeight;
  }

  List<Task> tasksFor(String memberId) =>
      tasks.where((Task t) => t.assigneeId == memberId).toList();

  // ------------------------------------------------------------------ actions

  Future<void> signIn(Member member) async {
    currentUser = member;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, member.id);
    notifyListeners();
  }

  Future<void> signOut() async {
    currentUser = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }

  Future<void> saveTask(Task task, {bool isNew = false}) async {
    await _tasks.upsert(task);
    await _log(
      isNew
          ? 'created ${task.title}'
          : 'updated ${task.title}',
      isNew ? ActivityType.created : ActivityType.updated,
    );
    await refresh();
  }

  Future<void> changeTaskStatus(Task task, TaskStatus status) async {
    final int progress =
        status == TaskStatus.completed ? 100 : task.progress;
    await _tasks.upsert(
      task.copyWith(status: status, progress: progress),
    );
    await _log(
      'changed the status of ${task.title} to ${status.label}',
      status == TaskStatus.completed
          ? ActivityType.completed
          : ActivityType.statusChanged,
    );
    await refresh();
  }

  Future<void> deleteTask(Task task) async {
    await _tasks.delete(task.id);
    await _log('deleted ${task.title}', ActivityType.updated);
    await refresh();
  }

  Future<void> saveSettings(SlaSettings next) async {
    settings = next;
    await _settings.save(next);
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    await DbHelper.instance.resetToSeed();
    await load();
  }

  Future<void> _log(String action, ActivityType type) async {
    final Member? actor = currentUser;
    final String who = actor?.name ?? 'Someone';
    await _activity.add(
      Activity(
        id: _uuid.v4(),
        memberId: actor?.id ?? '',
        message: '$who $action',
        at: DateTime.now(),
        type: type,
      ),
    );
  }
}
