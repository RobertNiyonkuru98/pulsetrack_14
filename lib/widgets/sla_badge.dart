import 'package:flutter/material.dart';

import '../data/models/sla_status.dart';
import '../theme/app_colors.dart';

/// The solid colour of an SLA status (text + dot).
Color slaForeground(SlaStatus status) {
  switch (status) {
    case SlaStatus.onTrack:
      return AppColors.onTrack;
    case SlaStatus.atRisk:
      return AppColors.atRisk;
    case SlaStatus.overdue:
      return AppColors.overdue;
    case SlaStatus.completed:
      return AppColors.completed;
  }
}

/// The soft tinted background behind the badge.
Color slaBackground(SlaStatus status) {
  switch (status) {
    case SlaStatus.onTrack:
      return AppColors.onTrackSoft;
    case SlaStatus.atRisk:
      return AppColors.atRiskSoft;
    case SlaStatus.overdue:
      return AppColors.overdueSoft;
    case SlaStatus.completed:
      return AppColors.completedSoft;
  }
}

/// The pill badge used everywhere a status is shown.
class SlaBadge extends StatelessWidget {
  const SlaBadge({super.key, required this.status, this.dense = false});

  final SlaStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color fg = slaForeground(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: slaBackground(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
