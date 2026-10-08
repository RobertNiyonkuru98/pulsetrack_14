import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes.dart';
import 'screens/activity_log_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/member_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sla_settings_screen.dart';
import 'screens/task_details_screen.dart';
import 'screens/task_form_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/team_members_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider<AppState>(
      create: (_) => AppState()..load(),
      child: const PulseTrackApp(),
    ),
  );
}

class PulseTrackApp extends StatelessWidget {
  const PulseTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: Routes.signIn,
      routes: <String, WidgetBuilder>{
        Routes.signIn: (BuildContext context) => const SignInScreen(),
        Routes.dashboard: (BuildContext context) => const DashboardScreen(),
        Routes.tasks: (BuildContext context) => const TaskListScreen(),
        Routes.taskDetails: (BuildContext context) => TaskDetailsScreen(
              taskId: ModalRoute.of(context)?.settings.arguments as String?,
            ),
        Routes.taskForm: (BuildContext context) => TaskFormScreen(
              taskId: ModalRoute.of(context)?.settings.arguments as String?,
            ),
        Routes.team: (BuildContext context) => const TeamMembersScreen(),
        Routes.memberDetail: (BuildContext context) => MemberDetailScreen(
              memberId: ModalRoute.of(context)?.settings.arguments as String?,
            ),
        Routes.profile: (BuildContext context) => const ProfileScreen(),
        Routes.insights: (BuildContext context) => const InsightsScreen(),
        Routes.activity: (BuildContext context) => const ActivityLogScreen(),
        Routes.slaRules: (BuildContext context) => const SlaSettingsScreen(),
      },
    );
  }
}
