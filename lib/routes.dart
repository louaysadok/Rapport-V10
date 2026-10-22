import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/dashboard_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/report_screen.dart';
import 'screens/jury_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

/// Configuration de la navigation (go_router).
/// Bas de navigation : Accueil / Journal / Rapport / Soutenance / Profil.
final appRouter = GoRouter(
  initialLocation: '/settings',
  redirect: (context, state) {
    final first = ProviderScope.of(context).read(firstLaunchProvider);
    final isSettings = state.location == '/settings';
    if (first && !isSettings) return '/settings';
    if (!first && isSettings) return '/';
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/journal',
          name: 'journal',
          builder: (context, state) => const JournalScreen(),
        ),
        GoRoute(
          path: '/report',
          name: 'report',
          builder: (context, state) => const ReportScreen(),
        ),
        GoRoute(
          path: '/jury',
          name: 'jury',
          builder: (context, state) => const JuryScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

/// Coque des cinq onglets avec barre de navigation inférieure.
class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = GoRouter.of(context).location;
    final index = _indexForLocation(loc);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          switch (i) {
            case 0: context.go('/'); break;
            case 1: context.go('/journal'); break;
            case 2: context.go('/report'); break;
            case 3: context.go('/jury'); break;
            case 4: context.go('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Journal'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Rapport'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Soutenance'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  int _indexForLocation(String loc) {
    switch (loc) {
      case '/journal': return 1;
      case '/report': return 2;
      case '/jury': return 3;
      case '/profile': return 4;
      default: return 0;
    }
  }
}
