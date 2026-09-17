import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'cart_screen.dart';

class ReplaceOrderScreen extends StatelessWidget {
  const ReplaceOrderScreen({super.key});

  final MenuItem currentItem = const MenuItem(
    name: 'Chicken Rice',
    description: 'Stir-fried rice with chicken & veggies',
    price: 80,
    imageAsset: 'assets/images/chicken_rice_plate.jpg',
    category: 'Rice',
  );

  @override
  Widget build(BuildContext context) {
    final replacements = [
      const MenuItem(
        name: 'Veg Rice',
        description: 'Fresh veggie fried rice',
        price: 60,
        imageAsset: 'assets/images/veg_rice.jpg',
        category: 'Rice',
      ),
      const MenuItem(
        name: 'Chicken Noodles',
        description: 'Wok noodles with chicken',
        price: 90,
        imageAsset: 'assets/images/chicken_noodles.jpg',
        category: 'Snacks',
      ),
      const MenuItem(
        name: 'Veg Noodles',
        description: 'Noodles with vegetables',
        price: 70,
        imageAsset: 'assets/images/veg_noodles.jpg',
        category: 'Snacks',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: Column(
        children: [
          const _ReplaceHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.marginMobile),
              children: [
                const _SectionLabel('Current Item'),
                const SizedBox(height: AppSpacing.xs),
                _CurrentItemCard(item: currentItem),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel('Replace with'),
                const SizedBox(height: AppSpacing.sm),
                for (final item in replacements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ReplacementCard(
                      current: currentItem,
                      item: item,
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

class _ReplaceHeader extends StatelessWidget {
  const _ReplaceHeader();

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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          const Expanded(
            child: Text(
              'Replace Order',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _CurrentItemCard extends StatelessWidget {
  final MenuItem item;

  const _CurrentItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
            width: 64,
            height: 64,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Text(
            '₹${item.price}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplacementCard extends StatelessWidget {
  final MenuItem current;
  final MenuItem item;

  const _ReplacementCard({required this.current, required this.item});

  @override
  Widget build(BuildContext context) {
    int diff = item.price - current.price;
    final refund = diff < 0;
    final diffAbs = diff.abs();

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
                  '₹${item.price}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  refund ? 'Refund: ₹$diffAbs' : 'Pay extra: ₹$diffAbs',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                    color: refund
                        ? AppColors.successGreen
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            height: 40,
            child: FilledButton(
              onPressed: () {
                CartController.instance.add(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order replaced with ${item.name}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Replace',
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
    );
  }
}