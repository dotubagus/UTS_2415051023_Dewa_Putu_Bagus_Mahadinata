import 'package:flutter/material.dart';

import '../main.dart' show kIdlixRed;
import 'home_screen.dart';
import 'movie_list_screen.dart';
import 'watchlist_screen.dart';
import 'profile_screen.dart';

/// Shell navigasi utama bergaya IDLIX.
/// - Lebar < 700 px → NavigationBar di bawah.
/// - Lebar ≥ 700 px → pill navbar melayang di atas (logo + tab + akun).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    _TabItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    _TabItem(label: 'Browse', icon: Icons.search_outlined, activeIcon: Icons.search),
    _TabItem(label: 'Watchlist', icon: Icons.bookmark_outline, activeIcon: Icons.bookmark),
    _TabItem(label: 'Profil', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  late final List<Widget> _screens = const [
    HomeScreen(),
    MovieListScreen(),
    WatchlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    return isWide ? _buildWide() : _buildCompact();
  }

  Widget _buildCompact() {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: _tabs
              .map((t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.activeIcon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildWide() {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Text(
                      'CINELIST',
                      style: TextStyle(
                        color: kIdlixRed,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 28),
                    for (var i = 0; i < _tabs.length; i++)
                      _NavPill(
                        tab: _tabs[i],
                        selected: i == _selectedIndex,
                        onTap: () => setState(() => _selectedIndex = i),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final _TabItem tab;
  final bool selected;
  final VoidCallback onTap;
  const _NavPill({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? kIdlixRed : theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(selected ? tab.activeIcon : tab.icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                tab.label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabItem({required this.label, required this.icon, required this.activeIcon});
}
