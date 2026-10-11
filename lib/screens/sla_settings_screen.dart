import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/sla_settings.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../logic/sla_engine.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/sla_badge.dart';

/// Screen 10 - SLA Rules & Thresholds. OWNER: Robert.
///
/// The screen the whole SLA idea hangs on. The thresholds the engine uses are
/// **data, not constants**: editing one here re-scores a real task in the live
/// preview, and saving writes it through [AppState] - which calls
/// `notifyListeners()`, so every badge in the app follows without a restart.
///
/// The one thing to remember when reading this file: nothing here computes a
/// status by hand. The preview calls [SlaEngine] exactly the same way the
/// Dashboard does, so the preview cannot drift from the real thing.
class SlaSettingsScreen extends StatefulWidget {
  const SlaSettingsScreen({super.key});

  @override
  State<SlaSettingsScreen> createState() => _SlaSettingsScreenState();
}

class _SlaSettingsScreenState extends State<SlaSettingsScreen> {
  /// The values being edited. Null means "show whatever is saved", so the
  /// screen re-syncs by itself after a save or a reset.
  SlaSettings? _draft;

  static const SlaSettings _defaults = SlaSettings();

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final SlaSettings saved = state.settings;
    final SlaSettings draft = _draft ?? saved;
    final bool dirty = !_same(draft, saved);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('SLA Rules')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: <Widget>[
          const Text(
            'The thresholds behind every SLA badge in the app. Change one and '
            'the preview below re-scores a real task before you commit.',
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),

          _Card(
            title: 'At-Risk threshold',
            caption: 'How much of a task\'s window must still be left. Drop '
                'below it and the task is At Risk. Higher priority warns '
                'earlier.',
            child: Column(
              children: <Widget>[
                _threshold(
                  context,
                  label: 'Critical',
                  value: draft.criticalThreshold,
                  apply: (double v) => draft.copyWith(criticalThreshold: v),
                ),
                _threshold(
                  context,
                  label: 'High',
                  value: draft.highThreshold,
                  apply: (double v) => draft.copyWith(highThreshold: v),
                ),
                _threshold(
                  context,
                  label: 'Medium',
                  value: draft.mediumThreshold,
                  apply: (double v) => draft.copyWith(mediumThreshold: v),
                ),
                _threshold(
                  context,
                  label: 'Low',
                  value: draft.lowThreshold,
                  apply: (double v) => draft.copyWith(lowThreshold: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _Card(
            title: 'Behaviour',
            child: Column(
              children: <Widget>[
                _toggle(
                  label: 'Flag blocked tasks as At Risk',
                  caption: 'Blocked work cannot make progress, so escalate it.',
                  value: draft.flagBlockedAsAtRisk,
                  apply: (bool v) => draft.copyWith(flagBlockedAsAtRisk: v),
                ),
                const Divider(height: 22),
                _toggle(
                  label: 'Warn under 24 hours',
                  caption: 'The hard safety net, whatever the priority.',
                  value: draft.warnUnder24h,
                  apply: (bool v) => draft.copyWith(warnUnder24h: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _PreviewCard(state: state, draft: draft, saved: saved),
          const SizedBox(height: 22),

          FilledButton(
            onPressed: dirty ? () => _save(state, draft) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Save rules',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _same(draft, _defaults)
                ? null
                : () => _save(state, _defaults),
            child: const Text('Restore defaults'),
          ),
        ],
      ),
    );
  }

  /// Writes `next` through AppState - which persists it AND calls
  /// notifyListeners(), so the badges on every other screen repaint.
  Future<void> _save(AppState state, SlaSettings next) async {
    setState(() => _draft = null);
    await state.saveSettings(next);
  }

  Widget _threshold(
    BuildContext context, {
    required String label,
    required double value,
    required SlaSettings Function(double value) apply,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            thumbColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            overlayColor: AppColors.primarySoft,
            trackHeight: 5,
          ),
          child: Slider(
            value: value,
            min: 0.05,
            max: 0.95,
            // 18 steps = 5% at a time, and every default lands exactly on one.
            divisions: 18,
            label: '${(value * 100).round()}%',
            onChanged: (double v) => setState(() => _draft = apply(v)),
          ),
        ),
      ],
    );
  }

  Widget _toggle({
    required String label,
    required String caption,
    required bool value,
    required SlaSettings Function(bool value) apply,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          activeThumbColor: AppColors.primary,
          onChanged: (bool v) => setState(() => _draft = apply(v)),
        ),
      ],
    );
  }

  static bool _same(SlaSettings a, SlaSettings b) =>
      a.criticalThreshold == b.criticalThreshold &&
      a.highThreshold == b.highThreshold &&
      a.mediumThreshold == b.mediumThreshold &&
      a.lowThreshold == b.lowThreshold &&
      a.flagBlockedAsAtRisk == b.flagBlockedAsAtRisk &&
      a.warnUnder24h == b.warnUnder24h;
}

// ------------------------------------------------------------------ preview

/// Re-scores one real task with the values being edited.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.state,
    required this.draft,
    required this.saved,
  });

  final AppState state;
  final SlaSettings draft;
  final SlaSettings saved;

  /// Picks the open task whose status is most sensitive to the thresholds: the
  /// one sitting closest to its own threshold. A task that is comfortably On
  /// Track would teach nothing, because no sane threshold would flip it.
  ///
  /// Overdue tasks and tasks inside the 24-hour net are skipped - rules 3 and 4
  /// fire before the threshold rule, so a threshold change cannot move them.
  static Task? _sampleTask(AppState state, SlaSettings s) {
    final DateTime now = DateTime.now();
    Task? best;
    double bestMargin = double.infinity;

    for (final Task t in state.tasks) {
      if (t.status == TaskStatus.completed) continue;
      if (now.isAfter(t.dueDate)) continue;
      final int total = t.dueDate.difference(t.createdAt).inMinutes;
      if (total <= 0) continue;
      final int remaining = t.dueDate.difference(now).inMinutes;
      if (s.warnUnder24h && remaining <= 24 * 60) continue;

      final double margin =
          (remaining / total - SlaEngine.thresholdFor(t.priority, s)).abs();
      if (margin < bestMargin) {
        bestMargin = margin;
        best = t;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final Task? task = _sampleTask(state, draft);

    if (task == null) {
      return const _Card(
        title: 'Live preview',
        child: Text(
          'No open task is decided by a threshold right now - the 24-hour rule '
          'and overdue tasks both take priority over it. The sliders still '
          'apply to tasks created from here on.',
          style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
        ),
      );
    }

    final SlaStatus withDraft = SlaEngine.evaluate(task, settings: draft);
    final SlaStatus withSaved = SlaEngine.evaluate(task, settings: saved);
    final bool changed = withDraft != withSaved;

    return _Card(
      title: 'Live preview',
      caption: 'One real task, re-scored with the values above.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SlaBadge(status: withDraft),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${task.project}  ·  ${task.priority.label} priority',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: changed ? AppColors.primarySoft : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              SlaEngine.explain(task, settings: draft),
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.ink,
                height: 1.45,
              ),
            ),
          ),
          if (changed) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Saved rules make this ${withSaved.label} - these rules '
                    'make it ${withDraft.label}.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- small parts

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.caption});

  final String title;
  final Widget child;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
