import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'contact_screen.dart';
import 'login_screen.dart';
import 'menu_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: Column(
        children: [
          _ProfileHeader(cart: cart),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: const [
                _ProfileCard(),
                SizedBox(height: AppSpacing.lg),
                _MenuList(),
                SizedBox(height: AppSpacing.lg),
                _FrequentItems(),
                SizedBox(height: AppSpacing.md),
                _LogoutButton(),
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
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
    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/avatar.jpg',
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return const IniAvatar(
                label: 'John Doe',
                size: 96,
                background: AppColors.surfaceContainer,
                foreground: AppColors.primaryContainer,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'John Doe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const Text(
          'johndoe@student.tce.edu',
          style: TextStyle(fontSize: 14, color: AppColors.secondary),
        ),
      ],
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
              MaterialPageRoute(builder: (_) => const _OrdersPlaceholder()),
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

class _OrdersPlaceholder extends StatelessWidget {
  const _OrdersPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Order history coming soon',
          style: TextStyle(color: AppColors.secondary, fontSize: 14),
        ),
      ),
    );
  }
}

class _FrequentItems extends StatelessWidget {
  const _FrequentItems();

  @override
  Widget build(BuildContext context) {
    final items = MenuCatalog.items
        .where((i) => i.timesOrdered > 0)
        .toList()
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
        for (final item in items)
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
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () {
          CartController.instance.clear();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
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