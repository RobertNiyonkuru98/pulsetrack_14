import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme/app_colors.dart';

/// The floating dark pill navigation bar from the Figma design.
///
/// It is a [Scaffold.bottomNavigationBar], so the padding around the pill is
/// transparent and the page background shows through - that is what makes the
/// bar look like it is hovering rather than bolted to the bottom edge.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const List<String> _labels = <String>[
    'Dashboard',
    'Tasks',
    'Team',
    'Profile',
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.home_outlined,
    Icons.checklist_outlined,
    Icons.groups_outlined,
    Icons.account_circle_outlined,
  ];

  static const List<IconData> _activeIcons = <IconData>[
    Icons.home_rounded,
    Icons.checklist_rounded,
    Icons.groups_rounded,
    Icons.account_circle,
  ];

  static const List<String> _routes = <String>[
    Routes.dashboard,
    Routes.tasks,
    Routes.team,
    Routes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.navBackground,
          borderRadius: BorderRadius.circular(34),
        ),
        child: Row(
          children: List<Widget>.generate(4, (int i) {
            final bool active = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (active) return;
                  Navigator.pushReplacementNamed(context, _routes[i]);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        active ? _activeIcons[i] : _icons[i],
                        size: 20,
                        color: active ? Colors.white : AppColors.navInactive,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _labels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          color: active ? Colors.white : AppColors.navInactive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
