import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/skills/screens/skills_screen.dart';
import 'features/projects/screens/projects_screen.dart';
import 'features/tasks/screens/tasks_screen.dart';
import 'features/placement/screens/placement_screen.dart';
import 'features/intro/screens/splash_screen.dart';
import 'features/notes_planner/screens/notes_planner_hub_screen.dart';
import 'features/skills/screens/career_roadmaps_screen.dart';
import 'features/resume/screens/resume_screen.dart';
import 'features/portfolio/screens/public_portfolio_screen.dart';
import 'services/navigation_state_service.dart';

class SkillTrackApp extends StatelessWidget {
  final Widget? initialHome;
  const SkillTrackApp({super.key, this.initialHome});

  /// Extracts a public portfolio handle from Uri, supporting both
  /// hash routing (/#/p/username) and path routing (/p/username).
  static String? extractPublicHandle(Uri uri) {
    // 1. Check hash/fragment routing: e.g. #/p/priya-sharma
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final clean = fragment.startsWith('/') ? fragment : '/$fragment';
      final fragUri = Uri.tryParse(clean);
      if (fragUri != null && fragUri.pathSegments.isNotEmpty) {
        if (fragUri.pathSegments.first == 'p' && fragUri.pathSegments.length >= 2) {
          return fragUri.pathSegments[1];
        }
      }
    }

    // 2. Check path routing: e.g. /p/priya-sharma
    if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'p' &&
        uri.pathSegments.length >= 2) {
      return uri.pathSegments[1];
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final publicHandle = extractPublicHandle(Uri.base);
    final homeWidget = initialHome ??
        (publicHandle != null
            ? PublicPortfolioScreen(handle: publicHandle)
            : const SplashScreen());

    return MaterialApp(
      title: 'SkillTrack',
      restorationScopeId: 'skilltrack_app',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: homeWidget,
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/p/')) {
          final handle = settings.name!.replaceFirst('/p/', '').split('?').first;
          return MaterialPageRoute(
            builder: (_) => PublicPortfolioScreen(handle: handle),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  final String? initialRoute;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
    this.initialRoute,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with WidgetsBindingObserver {
  late int _currentIndex;
  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();
  final GlobalKey<SkillsScreenState> _skillsKey =
      GlobalKey<SkillsScreenState>();
  final GlobalKey<ProjectsScreenState> _projectsKey =
      GlobalKey<ProjectsScreenState>();
  final GlobalKey<TasksScreenState> _tasksKey =
      GlobalKey<TasksScreenState>();
  final GlobalKey<PlacementScreenState> _placementKey =
      GlobalKey<PlacementScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    WidgetsBinding.instance.addObserver(this);
    _checkRestoreState();
  }

  Future<void> _checkRestoreState() async {
    if (widget.initialIndex == 0) {
      final savedTab = await NavigationStateService.instance.getActiveTab();
      if (mounted && savedTab != _currentIndex) {
        setState(() {
          _currentIndex = savedTab.clamp(0, 4);
        });
      }
    }

    final route = widget.initialRoute ??
        await NavigationStateService.instance.getActiveRoute();
    if (route != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _resumeSubRoute(route);
      });
    }
  }

  void _resumeSubRoute(String route) {
    NavigationStateService.instance.saveActiveRoute(null);
    Widget? targetScreen;
    if (route == 'notes_planner') {
      targetScreen = const NotesPlannerHubScreen();
    } else if (route == 'career_roadmaps') {
      targetScreen = const CareerRoadmapsScreen();
    } else if (route == 'resume_builder') {
      targetScreen = const ResumeScreen();
    }

    if (targetScreen != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => targetScreen!),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      NavigationStateService.instance.saveActiveTab(_currentIndex);
      NavigationStateService.instance.recordAppBackgrounded();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    final clamped = index.clamp(0, 4);
    setState(() {
      _currentIndex = clamped;
    });
    NavigationStateService.instance.saveActiveTab(clamped);
    if (clamped == 0) {
      _dashboardKey.currentState?.reload();
    } else if (clamped == 1) {
      _skillsKey.currentState?.reload();
    } else if (clamped == 2) {
      _projectsKey.currentState?.reload();
    } else if (clamped == 3) {
      _tasksKey.currentState?.reload();
    } else if (clamped == 4) {
      _placementKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      DashboardScreen(
        key: _dashboardKey,
        onNavigateTab: _onTabSelected,
      ),
      SkillsScreen(key: _skillsKey),
      ProjectsScreen(key: _projectsKey),
      TasksScreen(key: _tasksKey),
      PlacementScreen(key: _placementKey),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: destinations,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.code_outlined),
              selectedIcon: Icon(Icons.code_rounded),
              label: 'Skills',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_special_outlined),
              selectedIcon: Icon(Icons.folder_special_rounded),
              label: 'Portfolio',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_rtl_outlined),
              selectedIcon: Icon(Icons.checklist_rtl_rounded),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school_rounded),
              label: 'Placement',
            ),
          ],
        ),
      ),
    );
  }
}
