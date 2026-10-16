import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'admin_menu_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_users_screen.dart';

/// Root shell for administrators.
///
/// Shows a persistent Menu/Users/Profile bottom bar. Each tab has its own
/// nested [Navigator] so pushed screens keep the bar visible.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  final _menuNavKey = GlobalKey<NavigatorState>();
  final _usersNavKey = GlobalKey<NavigatorState>();
  final _profileNavKey = GlobalKey<NavigatorState>();

  NavigatorState get _currentNav => switch (_index) {
        0 => _menuNavKey.currentState!,
        1 => _usersNavKey.currentState!,
        _ => _profileNavKey.currentState!,
      };

  void _selectTab(int index) {
    if (index == _index) {
      _currentNav.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _index = index);
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    final nav = _currentNav;
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    await SystemNavigator.pop();
  }

  Widget _tab(GlobalKey<NavigatorState> key, Widget child) {
    return Navigator(
      key: key,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            _tab(_menuNavKey, const AdminMenuScreen()),
            _tab(_usersNavKey, const AdminUsersScreen()),
            _tab(_profileNavKey, const AdminProfileScreen()),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            border: const Border(
              top: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AdminNavItem(
                    icon: Icons.restaurant_menu,
                    label: 'Menu',
                    active: _index == 0,
                    onTap: () => _selectTab(0),
                  ),
                  _AdminNavItem(
                    icon: Icons.people,
                    label: 'Users',
                    active: _index == 1,
                    onTap: () => _selectTab(1),
                  ),
                  _AdminNavItem(
                    icon: Icons.person,
                    label: 'Profile',
                    active: _index == 2,
                    onTap: () => _selectTab(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.secondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: active ? 1.1 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24, fill: active ? 1.0 : 0.0),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
