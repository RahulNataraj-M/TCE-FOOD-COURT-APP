import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import '../models/menu_item.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'cart_screen.dart';
import 'cancel_order_screen.dart';
import 'contact_screen.dart';
import 'menu_screen.dart';
import 'replace_order_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final menuController = AppScope.of(context).menuController;
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: Column(
        children: [
          _HomeHeader(cart: cart),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 80),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                  ),
                  child: _Greeting(),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListenableBuilder(
                  listenable: menuController,
                  builder: (context, _) =>
                      _MostOrderedSection(items: menuController.items),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _QuickActions(),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final CartController cart;

  const _HomeHeader({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.onSecondaryContainer,
            ),
          ),
          const Expanded(
            child: Text(
              'TCE Food Court',
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
                      MaterialPageRoute(
                        builder: (_) => const CartScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.shopping_cart,
                    color: AppColors.onSecondaryContainer,
                  ),
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

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good evening 👋',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        const Text(
          'What are you hungry for?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            height: 40 / 32,
            letterSpacing: -0.64,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _MostOrderedSection extends StatelessWidget {
  final List<MenuItem> items;

  const _MostOrderedSection({required this.items});

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'Most Ordered',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MenuScreen()),
              );
            },
            child: const Text(
              'See All',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final popular = items.where((i) => i.rating > 0).toList();
    return Column(
      children: [
        _header(context),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
            ),
            itemCount: popular.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) => _MostOrderedCard(item: popular[i]),
          ),
        ),
      ],
    );
  }
}

class _MostOrderedCard extends StatelessWidget {
  final MenuItem item;

  const _MostOrderedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MenuScreen()),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FoodImage(
                      asset: item.imageAsset,
                      fallbackLabel: item.name,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppColors.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.statusPending,
                              fill: 1,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.rating
                                  .toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          CartController.instance.add(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to cart'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.add,
                            size: 18,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.restaurant_menu,
                  iconBg: AppColors.primaryContainer.withValues(alpha: 0.1),
                  iconColor: AppColors.primary,
                  label: 'Order',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MenuScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.support_agent,
                  iconBg: AppColors.surfaceContainer,
                  iconColor: AppColors.secondary,
                  label: 'Contact Us',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ContactScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.cancel,
                  iconBg: AppColors.errorContainer.withValues(alpha: 0.3),
                  iconColor: AppColors.error,
                  label: 'Cancel Order',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CancelOrderScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.published_with_changes,
                  iconBg: AppColors.surfaceContainer,
                  iconColor: AppColors.secondary,
                  label: 'Replace Order',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReplaceOrderScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}