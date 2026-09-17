import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MenuItem> get _filtered {
    return MenuCatalog.items.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final query = _query.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty || item.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      body: Stack(
        children: [
          Column(
            children: [
              _MenuHeader(cart: cart),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.marginMobile,
                    right: AppSpacing.marginMobile,
                    bottom: 160,
                    top: AppSpacing.md,
                  ),
                  children: [
                    _SearchBar(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: AppSpacing.marginMobile),
                    _CategoryChips(
                      selected: _selectedCategory,
                      onSelected: (c) => setState(() => _selectedCategory = c),
                    ),
                    const SizedBox(height: AppSpacing.marginMobile),
                    ..._filtered.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _MenuFoodCard(item: item),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
            bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
            child: ListenableBuilder(
              listenable: cart,
              builder: (context, _) {
                if (cart.itemCount == 0) return const SizedBox.shrink();
                return _FloatingCartBar(
                  itemCount: cart.itemCount,
                  total: cart.total,
                  onViewCart: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CartScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  final CartController cart;

  const _MenuHeader({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          const Expanded(
            child: Text(
              'Order Food',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
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
                    color: AppColors.primary,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 2,
                  child: CartBadge(count: cart.itemCount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search food...',
                hintStyle: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                ),
                isCollapsed: true,
              ),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MenuCatalog.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final category = MenuCatalog.categories[i];
          final active = category == selected;
          return GestureDetector(
            onTap: () => onSelected(category),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: active ? AppColors.primaryContainer : AppColors.borderSubtle,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: active ? AppColors.onPrimary : AppColors.secondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuFoodCard extends StatefulWidget {
  final MenuItem item;

  const _MenuFoodCard({required this.item});

  @override
  State<_MenuFoodCard> createState() => _MenuFoodCardState();
}

class _MenuFoodCardState extends State<_MenuFoodCard> {
  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FoodImage(
            asset: widget.item.imageAsset,
            fallbackLabel: widget.item.name,
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
                  widget.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ListenableBuilder(
                  listenable: cart,
                  builder: (context, _) {
                    final inCart = cart.items
                        .where((c) => c.item.name == widget.item.name)
                        .firstOrNull;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${widget.item.price}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        if (inCart == null)
                          _AddButton(item: widget.item)
                        else
                          _QuantityControl(item: widget.item),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final MenuItem item;

  const _AddButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilledButton(
        onPressed: () => CartController.instance.add(item),
        style: FilledButton.styleFrom(
          backgroundColor:
              AppColors.primaryContainer.withValues(alpha: 0.1),
          foregroundColor: AppColors.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: AppColors.primaryContainer.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: const Text(
          'Add',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final MenuItem item;

  const _QuantityControl({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;
    final count =
        cart.items.where((c) => c.item.name == item.name).firstOrNull?.quantity ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => cart.decrement(item),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 2),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.remove,
                size: 14,
                color: AppColors.primaryContainer,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => cart.increment(item),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 2),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add,
                size: 14,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCartBar extends StatelessWidget {
  final int itemCount;
  final int total;
  final VoidCallback onViewCart;

  const _FloatingCartBar({
    required this.itemCount,
    required this.total,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.md,
              AppSpacing.marginMobile, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: AppColors.onPrimary),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
              Text(
                '₹$total',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onViewCart,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.onPrimary,
              foregroundColor: AppColors.primaryContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Cart',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.arrow_forward, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}