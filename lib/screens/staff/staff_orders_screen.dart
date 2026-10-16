import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/app_scope.dart';
import '../../theme/app_theme.dart';

/// Staff dashboard showing every active order across all students.
///
/// Orders are grouped by status and can be advanced with one tap:
/// Placed → Preparing → Ready → Completed (or Cancelled at any point).
class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  List<Order> _orders = const [];
  bool _isLoading = true;
  Object? _error;
  bool _showHistory = false;
  bool _didSubscribe = false;
  StreamSubscription<List<Order>>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSubscribe) return;
    _didSubscribe = true;
    _subscribe();
  }

  /// Subscribes to the live order queue. New orders placed by students appear
  /// automatically, and status changes made here are reflected everywhere.
  void _subscribe() {
    _subscription?.cancel();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _subscription =
        AppScope.of(context).orderRepository.watchAllOrders().listen(
      (orders) {
        if (!mounted) return;
        setState(() {
          _orders = orders;
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

  Future<void> _updateStatus(Order order, OrderStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.of(context).orderRepository.updateStatus(order, status);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      body: Column(
        children: [
          _StaffHeader(orderCount: _orders.where((o) => o.isActive).length),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _subscribe)
                    : _OrderQueue(
                        orders: _orders,
                        showHistory: _showHistory,
                        onToggleHistory: () =>
                            setState(() => _showHistory = !_showHistory),
                        onUpdateStatus: _updateStatus,
                      ),
          ),
        ],
      ),
    );
  }
}

class _StaffHeader extends StatelessWidget {
  final int orderCount;

  const _StaffHeader({required this.orderCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Incoming Orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (orderCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$orderCount active',
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderQueue extends StatelessWidget {
  final List<Order> orders;
  final bool showHistory;
  final VoidCallback onToggleHistory;
  final void Function(Order, OrderStatus) onUpdateStatus;

  const _OrderQueue({
    required this.orders,
    required this.showHistory,
    required this.onToggleHistory,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final active = orders.where((o) => o.isActive).toList();
    final closed = orders.where((o) => !o.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      children: [
        if (active.isEmpty)
          const _EmptyState()
        else ...[
          for (final order in active)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _StaffOrderCard(
                order: order,
                onUpdateStatus: onUpdateStatus,
              ),
            ),
        ],
        if (closed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            onTap: onToggleHistory,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Completed & Cancelled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    showHistory
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
          if (showHistory)
            for (final order in closed.take(20))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _StaffOrderCard(
                  order: order,
                  onUpdateStatus: onUpdateStatus,
                ),
              ),
        ],
      ],
    );
  }
}

class _StaffOrderCard extends StatelessWidget {
  final Order order;
  final void Function(Order, OrderStatus) onUpdateStatus;

  const _StaffOrderCard({required this.order, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.placed => AppColors.statusPending,
      OrderStatus.preparing => AppColors.tertiary,
      OrderStatus.ready => AppColors.successGreen,
      OrderStatus.completed => AppColors.secondary,
      OrderStatus.cancelled => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.id,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          if (order.userEmail != null) ...[
            const SizedBox(height: 2),
            Text(
              order.userEmail!,
              style: const TextStyle(fontSize: 12, color: AppColors.secondary),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${item.quantity} × ${item.name}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                '₹${order.total}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (order.isActive)
                _StatusButtons(order: order, onUpdateStatus: onUpdateStatus),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusButtons extends StatelessWidget {
  final Order order;
  final void Function(Order, OrderStatus) onUpdateStatus;

  const _StatusButtons({required this.order, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final buttons = switch (order.status) {
      OrderStatus.placed => [
          (label: 'Start Preparing', status: OrderStatus.preparing),
          (label: 'Cancel', status: OrderStatus.cancelled),
        ],
      OrderStatus.preparing => [
          (label: 'Mark Ready', status: OrderStatus.ready),
          (label: 'Cancel', status: OrderStatus.cancelled),
        ],
      OrderStatus.ready => [
          (label: 'Complete', status: OrderStatus.completed),
          (label: 'Cancel', status: OrderStatus.cancelled),
        ],
      _ => const <({String label, OrderStatus status})>[],
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final button in buttons)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: SizedBox(
              height: 32,
              child: button.status == OrderStatus.cancelled
                  ? OutlinedButton(
                      onPressed: () => onUpdateStatus(order, button.status),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      child: Text(
                        button.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                  : FilledButton(
                      onPressed: () => onUpdateStatus(order, button.status),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      child: Text(
                        button.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl * 3),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.secondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No active orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'New orders will appear here in real time.',
            style: TextStyle(fontSize: 14, color: AppColors.secondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Could not load orders.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
