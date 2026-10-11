import 'package:flutter/material.dart';

import '../theme/app_colors.dart';


class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.showDot = false,
    this.background = AppColors.surface,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final bool showDot;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final Widget button = Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.45, color: AppColors.ink),
        ),
      ),
    );

    final Widget withDot = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        button,
        if (showDot)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.overdue,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
            ),
          ),
      ],
    );

    return tooltip == null ? withDot : Tooltip(message: tooltip!, child: withDot);
  }
}