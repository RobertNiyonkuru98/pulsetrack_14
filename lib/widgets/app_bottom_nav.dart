import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme/app_colors.dart';

/// The floating black pill that sits at the bottom of every top-level screen.

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const List<String> _labels = <String>['Home', 'Tasks', 'Team', 'Profile'];

  static const List<IconData> _icons = <IconData>[
    Icons.home_outlined,
    Icons.checklist_outlined,
    Icons.groups_outlined,
    Icons.person_outline,
  ];

  static const List<IconData> _activeIcons = <IconData>[
    Icons.home_rounded,
    Icons.checklist_rounded,
    Icons.groups_rounded,
    Icons.person_rounded,
  ];

  static const List<String> _routes = <String>[
    Routes.dashboard,
    Routes.tasks,
    Routes.team,
    Routes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(4, _button),
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(int i) {
    final bool active = i == currentIndex;
    return Builder(
      builder: (BuildContext context) => Semantics(
        button: true,
        selected: active,
        label: _labels[i],
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (active) return;
            Navigator.pushReplacementNamed(context, _routes[i]);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : const Color(0xFF2A2A2A),
              shape: BoxShape.circle,
            ),
            child: Icon(
              active ? _activeIcons[i] : _icons[i],
              size: 22,
              color: active ? Colors.white : const Color(0xFFB5B5C0),
            ),
          ),
        ),
      ),
    );
  }
}