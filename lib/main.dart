// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/profile/profile_page.dart';
import 'features/progress/progress_page.dart';   // 👈 new
// (DashboardPage and MealsPage are still simple stubs for now)

void main() => runApp(const ProviderScope(child: NutriPulseApp()));

class NutriPulseApp extends StatelessWidget {
  const NutriPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriPulse',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const _HomeShell(),
    );
  }
}

/// Bottom-nav shell
class _HomeShell extends StatefulWidget {
  const _HomeShell({super.key});
  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  final _pages = const [
    DashboardPage(),
    MealsPage(),
    ProgressPage(), // ← real progress screen
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Meals'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Progress'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Simple placeholder pages — replace when you build these features
// ------------------------------------------------------------------
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Dashboard'));
}

class MealsPage extends StatelessWidget {
  const MealsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Meals'));
}
