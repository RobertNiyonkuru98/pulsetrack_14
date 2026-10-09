import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/member.dart';
import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/empty_state.dart';

/// Profile. OWNER: Admire.
///
/// The bottom-nav "Profile" tab. Shows who is signed in, a quick summary of
/// their tasks, and the actions a demo needs: SLA rules, the activity log,
/// resetting the demo data, and signing out.
///
/// READING GUIDE: build() picks the body (not signed in vs signed in), then
/// _ProfileBody.build() is a flat recipe of named pieces.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ==================================================================== actions

  Future<void> _confirmReset(BuildContext context, AppState state) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => _resetDialog(dialogContext),
    );

    if (confirmed != true) return;

    await state.resetDemoData();
    if (context.mounted) {
      _toast(context, 'Demo data restored.');
    }
  }

  Future<void> _signOut(BuildContext context, AppState state) async {
    await state.signOut(); // clears the SharedPreferences session
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.signIn,
      (Route<dynamic> route) => false, // wipe the whole back stack
    );
  }

  // ====================================================================== build

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final Member? member = state.currentUser;

    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Widget body;
    if (member == null) {
      body = const _NotSignedIn();
    } else {
      body = _ProfileBody(
        state: state,
        member: member,
        onReset: () => _confirmReset(context, state),
        onSignOut: () => _signOut(context, state),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: body,
    );
  }
}

/// A vertical gap, so layouts read like "header, gap, stats, gap, tiles".
Widget _gap([double height = 16]) => SizedBox(height: height);

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// ============================================================== small widgets

/// What the user sees if they somehow land here without a session.
class _NotSignedIn extends StatelessWidget {
  const _NotSignedIn();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.person_off_outlined,
      title: 'Not signed in',
      message: 'Pick a team member on the sign-in screen first.',
      action: FilledButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.signIn,
          (Route<dynamic> route) => false,
        ),
        child: const Text('Go to Sign In'),
      ),
    );
  }
}

AlertDialog _resetDialog(BuildContext dialogContext) {
  return AlertDialog(
    title: const Text('Reset demo data?'),
    content: const Text(
      'Tasks and activity go back to the seeded demo set. '
      'Team members and your session are kept.',
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(dialogContext, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(dialogContext, true),
        child: const Text('Reset'),
      ),
    ],
  );
}

// =============================================================== profile body

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.state,
    required this.member,
    required this.onReset,
    required this.onSignOut,
  });

  final AppState state;
  final Member member;
  final VoidCallback onReset;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final List<Task> mine = state.tasksFor(member.id);
    final int completed = mine
        .where((Task t) => t.status == TaskStatus.completed)
        .length;

    // The whole screen, top to bottom.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _identityCard(member),
        _gap(16),
        _statsRow(assigned: mine.length, completed: completed),
        _gap(16),
        _ActionTile(
          icon: Icons.tune,
          label: 'SLA Rules',
          subtitle: 'At-Risk thresholds per priority',
          onTap: () => Navigator.pushNamed(context, Routes.slaRules),
        ),
        _gap(10),
        _ActionTile(
          icon: Icons.history,
          label: 'Activity Log',
          subtitle: 'Everything that happened recently',
          onTap: () => Navigator.pushNamed(context, Routes.activity),
        ),
        _gap(24),
        _resetButton(onReset),
        _gap(10),
        _signOutButton(onSignOut),
        _gap(8),
        const Text(
          'PulseTrack demo - local SQLite only.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  /// Avatar, name, role, email - who is signed in.
  Widget _identityCard(Member member) {
    final Widget avatar = CircleAvatar(
      radius: 38,
      backgroundColor: AppColors.primary,
      child: Text(
        member.initials,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    final Widget emailChip = member.email.isEmpty
        ? const SizedBox.shrink()
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              member.email,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: <Widget>[
          avatar,
          _gap(12),
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          _gap(4),
          Text(
            member.role,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          _gap(8),
          emailChip,
        ],
      ),
    );
  }

  Widget _statsRow({required int assigned, required int completed}) {
    final Widget assignedTile = _StatTile(
      label: 'Tasks assigned',
      value: '$assigned',
      icon: Icons.list_alt,
      color: AppColors.primary,
    );

    final Widget completedTile = _StatTile(
      label: 'Completed',
      value: '$completed',
      icon: Icons.task_alt,
      color: AppColors.onTrack,
    );

    return Row(
      children: <Widget>[Expanded(child: assignedTile), _gap(12), Expanded(child: completedTile)],
    );
  }

  Widget _resetButton(VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.restart_alt),
      label: const Text('Reset demo data'),
    );
  }

  Widget _signOutButton(VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.overdue,
        side: const BorderSide(color: AppColors.overdue),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Sign out'),
    );
  }
}

/// A small number-with-label tile for the stats row.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Widget iconBox = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: color),
    );

    final Widget numbers = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: <Widget>[iconBox, _gap(12), Expanded(child: numbers)],
      ),
    );
  }
}

/// One tappable row that navigates somewhere.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget leading = Icon(icon, size: 22, color: AppColors.primary);

    final Widget text = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
        ],
      ),
    );

    final Widget row = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[leading, _gap(12), text, const Icon(Icons.chevron_right, color: AppColors.muted)],
      ),
    );

    return Container(
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: row,
        ),
      ),
    );
  }
}