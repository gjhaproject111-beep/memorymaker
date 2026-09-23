import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/training/training_launcher_screen.dart';

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  const _Destination(this.label, this.icon, this.selectedIcon, this.screen);
}

/// The app's persistent shell: a bottom navigation bar on phones, a side
/// rail on wider screens (tablet / desktop / web), wrapping the six
/// top-level sections.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static final _destinations = [
    _Destination('Home', Icons.home, Icons.home, const HomeScreen()),
    _Destination('Training', Icons.bolt, Icons.bolt, const TrainingLauncherScreen()),
    _Destination('Progress', Icons.trending_up, Icons.trending_up, const ProgressScreen()),
    _Destination('Analytics', Icons.bar_chart, Icons.bar_chart, const AnalyticsScreen()),
    _Destination('Library', Icons.menu_book, Icons.menu_book, const LibraryScreen()),
    _Destination('Settings', Icons.settings, Icons.settings, const SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 760;
    final body = IndexedStack(
      index: _index,
      children: _destinations.map((d) => d.screen).toList(),
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.deepPlum,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.darkPlum,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              useIndicator: true,
              indicatorColor: AppColors.peach.withOpacity(0.18),
              selectedIconTheme: const IconThemeData(color: AppColors.peach),
              unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
              selectedLabelTextStyle: const TextStyle(color: AppColors.peach, fontWeight: FontWeight.w600),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1, color: AppColors.plumBorder),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepPlum,
      body: body,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.darkPlum,
          indicatorColor: AppColors.peach.withOpacity(0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.peach : AppColors.textMuted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? AppColors.peach : AppColors.textMuted);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _destinations
              .map((d) => NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label))
              .toList(),
        ),
      ),
    );
  }
}
