import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/member.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/avatar_stack.dart';
import '../widgets/empty_state.dart';

/// Profile. OWNER: Admire.
///
/// The bottom-nav "Profile" tab. Shows who is signed in, a quick summary of
/// their tasks, and the actions a demo needs: SLA rules, the activity log,
/// resetting the demo data, and signing out.
///
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: SafeArea(child: body),
    );
  }
}


/// A spacer that works in both directions: `size` wide inside a Row and `size`
/// tall inside a Column, so the same helper reads the same way in either layout.
///
/// It must set **both** dimensions. A `SizedBox(height: n)` has a width of zero,
/// so using one for horizontal spacing silently butts two widgets together.
Widget _gap([double size = 16]) => SizedBox(width: size, height: size);

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// ============================================================== small widgets

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
        style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
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
    final int overdue = mine
        .where((Task t) => state.statusOf(t) == SlaStatus.overdue)
        .length;

    // The whole screen, top to bottom.
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: <Widget>[
        _headline(),
        _gap(20),
        _identity(member),
        _gap(20),
        _statsRow(assigned: mine.length, completed: completed, overdue: overdue),
        _gap(20),
        _settingsPanel(context),
        _gap(16),
        _resetRow(onReset),
        _gap(10),
        _signOutRow(onSignOut),
        _gap(16),
        const Text(
          'PulseTrack demo - local SQLite only.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }


  Widget _headline() {
    return const Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: 'Your\n',
            style: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFFAAAAB5)),
          ),
          TextSpan(
            text: 'profile',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ],
      ),
      style: TextStyle(fontSize: 38, height: 1.05),
    );
  }

  /// User centred avatar, name, role pill and email.
  Widget _identity(Member member) {
    final Widget rolePill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        member.role,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: <Widget>[
          MemberAvatar(member: member, size: 96),
          _gap(12),
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          _gap(8),
          rolePill,
          if (member.email.isNotEmpty) ...<Widget>[
            _gap(8),
            Text(
              member.email,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsRow({
    required int assigned,
    required int completed,
    required int overdue,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            value: '$assigned',
            label: 'Assigned',
            fill: AppColors.primary,
            text: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$completed',
            label: 'Completed',
            fill: AppColors.onTrackSoft,
            text: AppColors.onTrackText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$overdue',
            label: 'Overdue',
            fill: AppColors.overdueSoft,
            text: AppColors.overdueText,
          ),
        ),
      ],
    );
  }

  /// One white panel holding the navigation rows.
  Widget _settingsPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: <Widget>[
          _ActionRow(
            icon: Icons.tune,
            label: 'SLA rules',
            subtitle: 'At-risk thresholds per priority',
            onTap: () => Navigator.pushNamed(context, Routes.slaRules),
          ),
          _ActionRow(
            icon: Icons.insights,
            label: 'Insights',
            subtitle: 'SLA breakdown, breaches and deadlines',
            onTap: () => Navigator.pushNamed(context, Routes.insights),
          ),
          _ActionRow(
            icon: Icons.history,
            label: 'Activity log',
            subtitle: 'Everything that happened recently',
            onTap: () => Navigator.pushNamed(context, Routes.activity),
          ),
        ],
      ),
    );
  }

  Widget _resetRow(VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.restart_alt),
      label: const Text('Reset demo data'),
    );
  }


  Widget _signOutRow(VoidCallback onPressed) {
    return Material(
      color: AppColors.overdueSoft.withValues(alpha: 0.3),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: const SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.logout, size: 20, color: AppColors.overdueText),
              SizedBox(width: 8),
              Text(
                'Sign out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.overdueText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.fill,
    required this.text,
  });

  final String value;
  final String label;
  final Color fill;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.pastelCard(fill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: text)),
        ],
      ),
    );
  }
}

/// One tappable row inside the settings panel.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
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
    final Widget leading = Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: AppColors.primary),
    );

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

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: <Widget>[
            leading,
            const SizedBox(width: 14),
            text,
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}