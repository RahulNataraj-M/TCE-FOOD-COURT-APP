import 'package:flutter/material.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';

class IniAvatar extends StatelessWidget {
  final String label;
  final double size;
  final Color background;
  final Color foreground;

  const IniAvatar({
    super.key,
    required this.label,
    this.size = double.infinity,
    this.background = AppColors.surfaceContainer,
    this.foreground = AppColors.primaryContainer,
  });

  @override
  Widget build(BuildContext context) {
    final text = label.isEmpty ? '?' : label.trim().substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      color: background,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: size == double.infinity ? 18 : size * 0.32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FoodImage extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final String fallbackLabel;

  const FoodImage({
    super.key,
    required this.asset,
    required this.fallbackLabel,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stack) {
          return IniAvatar(
            label: fallbackLabel,
            background: AppColors.surfaceContainerHighest,
          );
        },
      ),
    );
  }
}

class CartBadge extends StatelessWidget {
  final int count;

  const CartBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: AppColors.onError,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A small pill that renders an [OrderStatus] with its own label and colour.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  /// The user-facing label and colour for [status].
  static (String, Color) describe(OrderStatus status) => switch (status) {
    OrderStatus.placed => ('Placed', AppColors.statusPending),
    OrderStatus.preparing => ('Preparing', AppColors.tertiary),
    OrderStatus.ready => ('Ready', AppColors.successGreen),
    OrderStatus.completed => ('Completed', AppColors.successGreen),
    OrderStatus.cancelled => ('Cancelled', AppColors.error),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = describe(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}