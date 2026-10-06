import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import '../models/order.dart';
import '../services/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key, this.order});

  /// The order that was just saved to Firestore.
  ///
  /// Null falls back to the signed-in user's active order, which keeps the
  /// screen usable when it is opened without a freshly placed order.
  final Order? order;

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CartController.instance.clear();
    });
  }

  Order get _order =>
      widget.order ??
      AppScope.of(context).ordersController.activeOrder ??
      SampleOrders.activeOrder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
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
                const _SuccessIcon(),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Payment Successful',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Your order has been placed successfully.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                _OrderDetailsCard(order: _order),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const BottomNavScaffold(
                            selectedIndex: 1,
                          ),
                        ),
                        // Keep the root AuthGate route so a later sign out can
                        // still return to the login screen.
                        (route) => route.isFirst,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text(
                      'View Order',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const BottomNavScaffold(
                            selectedIndex: 0,
                          ),
                        ),
                        // Keep the root AuthGate route so a later sign out can
                        // still return to the login screen.
                        (route) => route.isFirst,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
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
        ),
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle,
        size: 48,
        color: AppColors.successGreen,
        fill: 1,
      ),
    );
  }
}

class _OrderDetailsCard extends StatelessWidget {
  final Order order;

  const _OrderDetailsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          _DetailRow(label: 'Order Number', value: order.id),
          const Divider(color: AppColors.borderSubtle, height: AppSpacing.md),
          _DetailRow(label: 'Total Amount', value: '₹${order.total}'),
          const Divider(color: AppColors.borderSubtle, height: AppSpacing.md),
          const _StatusRow(),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.secondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontSize: 14, color: AppColors.secondary),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.statusPending,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Order Placed',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
                color: AppColors.statusPending,
              ),
            ),
          ],
        ),
      ],
    );
  }
}