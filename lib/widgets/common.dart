import 'package:flutter/material.dart';
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