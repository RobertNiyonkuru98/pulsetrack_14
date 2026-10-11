import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/activity.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/activity_tile.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/empty_state.dart';

/// Activity Log. OWNER: Admire.
///
/// The full audit trail of all member activity.
/// 
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  /// null = "All".
  ActivityType? _filter;

  static const List<(String, ActivityType?)> _chips = <(String, ActivityType?)>[
    ('All', null),
    ('Status', ActivityType.statusChanged),
    ('Created', ActivityType.created),
    ('Assigned', ActivityType.assigned),
    ('Completed', ActivityType.completed),
    ('Updated', ActivityType.updated),
  ];

  /// "Today", "Yesterday" or "Earlier" for a time stamp.
  String _groupOf(DateTime at) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(at.year, at.month, at.day);
    final int diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Activity> visible = state.activity
        .where((Activity a) => _filter == null || a.type == _filter)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _topBar(context, state),
            _headline(),
            _chipRow(),
            const SizedBox(height: 8),
            Expanded(child: _list(state, visible)),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: <Widget>[
          CircleIconButton(
            icon: Icons.arrow_back,
            tooltip: 'Back',
            onPressed: () => Navigator.maybePop(context),
          ),
          const Spacer(),
          CircleIconButton(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onPressed: () => state.refresh(),
          ),
        ],
      ),
    );
  }

  Widget _headline() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: 'Recent ',
              style: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFFAAAAB5)),
            ),
            TextSpan(
              text: 'activity',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ],
        ),
        style: TextStyle(fontSize: 34, height: 1.1),
      ),
    );
  }

  Widget _chipRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _chips.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final (String label, ActivityType? type) = _chips[index];
          final bool selected = _filter == type;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink,
            ),
            selectedColor: AppColors.black,
            backgroundColor: AppColors.surface,
            onSelected: (_) => setState(() => _filter = type),
          );
        },
      ),
    );
  }

  Widget _list(AppState state, List<Activity> visible) {
    if (visible.isEmpty) {
      return EmptyState(
        icon: Icons.history_toggle_off,
        title: _filter == null ? 'No activity yet' : 'Nothing matches this filter',
        message: _filter == null
            ? 'Create or update a task and it will appear here.'
            : 'Try a different filter.',
        action: _filter == null
            ? null
            : OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
                onPressed: () => setState(() => _filter = null),
                child: const Text('Clear filter'),
              ),
      );
    }

    final List<Widget> rows = <Widget>[];
    String? lastGroup;
    for (final Activity a in visible) {
      final String group = _groupOf(a.at);
      if (group != lastGroup) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(
            group.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.muted,
            ),
          ),
        ));
        lastGroup = group;
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ActivityTile(
          activity: a,
          initials: state.memberById(a.memberId)?.initials ?? '?',
        ),
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: rows,
    );
  }
}