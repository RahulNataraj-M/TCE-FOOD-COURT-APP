import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'admin_menu_edit_screen.dart';

/// Admin menu management: lists all items with availability toggles and
/// add/edit/delete actions.
class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  List<MenuItem> _items = const [];
  bool _isLoading = true;
  Object? _error;
  bool _didSubscribe = false;
  StreamSubscription<List<MenuItem>>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSubscribe) return;
    _didSubscribe = true;
    _subscribe();
  }

  /// Subscribes to the live menu, including unavailable items, so the list
  /// reflects every add/edit/toggle/delete in real time.
  void _subscribe() {
    _subscription?.cancel();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _subscription =
        AppScope.of(context).menuRepository.watchAllMenu().listen(
      (items) {
        if (!mounted) return;
        setState(() {
          _items = items;
          _isLoading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = AppScope.of(context).menuRepository;
    try {
      await repo.updateItem(item.copyWith(available: !item.available));
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update availability: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Remove "${item.name}" from the menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final docId = item.docId;
    if (docId == null) return;
    try {
      await AppScope.of(context).menuRepository.deleteItem(docId);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openEditor({MenuItem? item}) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AdminMenuEditScreen(item: item)),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGray,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.marginMobile),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manage Menu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: AppSpacing.sm),
                            Text('$_error'),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton(
                              onPressed: _subscribe,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _subscribe(),
                        child: ListView(
                          padding: const EdgeInsets.all(
                            AppSpacing.marginMobile,
                          ),
                          children: [
                            for (final item in _items)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: _AdminMenuItemCard(
                                  item: item,
                                  onToggle: () => _toggleAvailability(item),
                                  onEdit: () => _openEditor(item: item),
                                  onDelete: () => _deleteItem(item),
                                ),
                              ),
                            const SizedBox(height: 72),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminMenuItemCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: item.available
                        ? AppColors.onSurface
                        : AppColors.secondary,
                    decoration:
                        item.available ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.price} · ${item.category}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: item.available,
            onChanged: (_) => onToggle(),
            activeThumbColor: AppColors.successGreen,
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.secondary),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
