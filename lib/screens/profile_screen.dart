import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import '../models/menu_item.dart';
import '../services/app_scope.dart';
import '../services/auth_service.dart';
import '../services/firebase_errors.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'contact_screen.dart';
import 'menu_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final services = AppScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: Column(
        children: [
          _ProfileHeader(cart: cart),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                const _ProfileCard(),
                const SizedBox(height: AppSpacing.lg),
                const _MenuList(),
                const SizedBox(height: AppSpacing.lg),
                ListenableBuilder(
                  listenable: services.menuController,
                  builder: (context, _) => _FrequentItems(
                    items: services.menuController.items,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _LogoutButton(authService: services.authService),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final CartController cart;

  const _ProfileHeader({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      child: Row(
        children: [
          const SizedBox(width: 48),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MenuScreen()),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart, color: AppColors.primary),
                ),
                Positioned(
                  right: 4,
                  top: 2,
                  child: ListenableBuilder(
                    listenable: cart,
                    builder: (context, _) =>
                        CartBadge(count: cart.itemCount),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).authService.currentUser;
    final name = user?.displayName?.trim();
    final email = user?.email;
    final photoUrl = user?.photoURL;

    return Column(
      children: [
        ClipOval(
          child: photoUrl == null || photoUrl.isEmpty
              // No Google profile photo: keep the bundled avatar.
              ? Image.asset(
                  'assets/images/avatar.jpg',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => _fallback(name, email),
                )
              : Image.network(
                  photoUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      _fallback(name, email),
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          (name == null || name.isEmpty) ? 'TCE Student' : name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          email ?? '',
          style: const TextStyle(fontSize: 14, color: AppColors.secondary),
        ),
      ],
    );
  }

  Widget _fallback(String? name, String? email) {
    return IniAvatar(
      label: name ?? email ?? '',
      size: 96,
      background: AppColors.surfaceContainer,
      foreground: AppColors.primaryContainer,
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileItem(
          icon: Icons.history,
          label: 'Order History',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        const _ProfileItem(
          icon: Icons.favorite,
          label: 'Frequent Items',
        ),
        const SizedBox(height: AppSpacing.xs),
        _ProfileItem(
          icon: Icons.mail,
          label: 'Contact Us',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ContactScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        const _ProfileItem(
          icon: Icons.chat,
          label: 'Feedback',
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ProfileItem({
    required this.icon,
    required this.label,
    this.onTap,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequentItems extends StatelessWidget {
  final List<MenuItem> items;

  const _FrequentItems({required this.items});

  @override
  Widget build(BuildContext context) {
    final frequent = items.where((i) => i.timesOrdered > 0).toList()
      ..sort((a, b) => b.timesOrdered.compareTo(a.timesOrdered));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            'Frequent Items',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        for (final item in frequent)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _FrequentItemCard(item: item),
          ),
      ],
    );
  }
}

class _FrequentItemCard extends StatelessWidget {
  final MenuItem item;

  const _FrequentItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          FoodImage(
            asset: item.imageAsset,
            fallbackLabel: item.name,
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ordered ${item.timesOrdered} ${item.timesOrdered == 1 ? 'time' : 'times'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () {
                      CartController.instance.add(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} added to cart'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final AuthService authService;

  const _LogoutButton({required this.authService});

  Future<void> _signOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    CartController.instance.clear();
    try {
      await authService.signOut();
      // The AuthGate renders the login screen for a signed-out session, but it
      // is the first route, so return to it from any pushed route.
      navigator.popUntil((route) => route.isFirst);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(FirebaseErrors.describe(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () => _signOut(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}