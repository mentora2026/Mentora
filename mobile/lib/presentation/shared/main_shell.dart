import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../recommendations/recommendations_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';

/// Main app shell shown after login + onboarding, with bottom navigation
/// across the core patient-facing sections.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    RecommendationsScreen(),
    ReportsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  static const _destinations = [
    (icon: Icons.home_outlined, selected: Icons.home_rounded, label: AppStrings.home),
    (icon: Icons.lightbulb_outline_rounded, selected: Icons.lightbulb_rounded, label: AppStrings.recommendations),
    (icon: Icons.bar_chart_outlined, selected: Icons.bar_chart_rounded, label: AppStrings.reports),
    (icon: Icons.notifications_none_rounded, selected: Icons.notifications_rounded, label: AppStrings.notifications),
    (icon: Icons.person_outline_rounded, selected: Icons.person_rounded, label: AppStrings.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final dest in _destinations)
              NavigationDestination(
                icon: Icon(dest.icon),
                selectedIcon: Icon(dest.selected),
                label: dest.label,
              ),
          ],
        ),
      ),
    );
  }
}
