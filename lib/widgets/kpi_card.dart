import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// One of the four big pastel number cards at the top of the Dashboard.
///
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fill,
    this.onFill,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? fill;
  final Color? onFill;


  (Color, Color) get _scheme {
    if (color == AppColors.primary) return (AppColors.primary, Colors.white);
    if (color == AppColors.onTrack) return (AppColors.onTrackSoft, AppColors.onTrackText);
    if (color == AppColors.atRisk) return (AppColors.atRiskSoft, AppColors.atRiskText);
    if (color == AppColors.overdue) return (AppColors.overdueSoft, AppColors.overdueText);
    return (color.withValues(alpha: 0.2), AppColors.ink);
  }

  @override
  Widget build(BuildContext context) {
    final Color background = fill ?? _scheme.$1;
    final Color text = onFill ?? _scheme.$2;

    return Container(
      height: 128,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.pastelCard(background),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 13, color: text)),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppColors.ink),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              height: 1,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}