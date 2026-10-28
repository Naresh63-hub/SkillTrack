import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/skills/screens/skills_screen.dart';
import 'features/projects/screens/projects_screen.dart';
import 'features/tasks/screens/tasks_screen.dart';
import 'features/placement/screens/placement_screen.dart';
import 'features/intro/screens/splash_screen.dart';

class SkillTrackApp extends StatelessWidget {
  const SkillTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index.clamp(0, 4);
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const SkillsScreen(),
      const ProjectsScreen(),
      const TasksScreen(),
      const PlacementScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: destinations,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.code_outlined),
            selectedIcon: Icon(Icons.code),
            label: 'Skills',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_special_outlined),
            selectedIcon: Icon(Icons.folder_special),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Placement',
          ),
        ],
      ),
    );
  }
}
