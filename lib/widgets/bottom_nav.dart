import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

/// Exposes the bottom navigation controller to descendants so pushed screens
/// (for example the order confirmation) can switch tabs programmatically.
class MainShellScope extends InheritedWidget {
  final int currentIndex;
  final void Function(int index) selectTab;

  const MainShellScope({
    super.key,
    required this.currentIndex,
    required this.selectTab,
    required super.child,
  });

  static MainShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellScope>();
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

/// Root shell shown once a user is signed in.
///
/// Keeps a persistent Home/Profile bottom bar visible on every page by giving
/// each tab its own [Navigator]. Pushes performed from inside a tab stay in
/// that tab, so the bar is never covered.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;
  final _homeNavKey = GlobalKey<NavigatorState>();
  final _profileNavKey = GlobalKey<NavigatorState>();

  NavigatorState get _currentNav =>
      (_index == 0 ? _homeNavKey : _profileNavKey).currentState!;

  void _selectTab(int index) {
    if (index == _index) {
      // Re-tapping the active tab returns it to its root screen.
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
    return MainShellScope(
      currentIndex: _index,
      selectTab: _selectTab,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: _handlePop,
        child: Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              _tab(_homeNavKey, const HomeScreen()),
              _tab(_profileNavKey, const ProfileScreen()),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              border: const Border(
                top: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: _NavBar(
              currentIndex: _index,
              onTap: _selectTab,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home,
              label: 'Home',
              active: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.person,
              label: 'Profile',
              active: currentIndex == 1,
              onTap: () => onTap(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
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
            Icon(
              icon,
              color: color,
              size: 24,
              fill: active ? 1.0 : 0.0,
            ),
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
