import 'package:flutter/material.dart';

import '../routes.dart';

/// The four-tab navigation bar shared by every top-level screen.
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
    Icons.home,
    Icons.checklist,
    Icons.groups,
    Icons.person,
  ];

  static const List<String> _routes = <String>[
    Routes.dashboard,
    Routes.tasks,
    Routes.team,
    Routes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (int index) {
        if (index == currentIndex) return;
        Navigator.pushReplacementNamed(context, _routes[index]);
      },
      destinations: List<Widget>.generate(
        4,
        (int i) => NavigationDestination(
          icon: Icon(_icons[i]),
          selectedIcon: Icon(_activeIcons[i]),
          label: _labels[i],
        ),
      ),
    );
  }
}
