import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF570000);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF800000);
  static const Color onPrimaryContainer = Color(0xFFFF8371);
  static const Color primaryFixed = Color(0xFFFFDAD4);
  static const Color primaryFixedDim = Color(0xFFFFB4A8);
  static const Color onPrimaryFixed = Color(0xFF410000);
  static const Color onPrimaryFixedVariant = Color(0xFF8F0F07);
  static const Color inversePrimary = Color(0xFFFFB4A8);

  static const Color secondary = Color(0xFF5D5E60);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDFDFE1);
  static const Color onSecondaryContainer = Color(0xFF616365);
  static const Color secondaryFixed = Color(0xFFE2E2E4);
  static const Color secondaryFixedDim = Color(0xFFC6C6C8);
  static const Color onSecondaryFixed = Color(0xFF1A1C1D);
  static const Color onSecondaryFixedVariant = Color(0xFF454749);

  static const Color tertiary = Color(0xFF00137F);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF0021B9);
  static const Color onTertiaryContainer = Color(0xFF94A0FF);
  static const Color tertiaryFixed = Color(0xFFDFE0FF);
  static const Color tertiaryFixedDim = Color(0xFFBCC2FF);
  static const Color onTertiaryFixed = Color(0xFF000C61);
  static const Color onTertiaryFixedVariant = Color(0xFF1830C2);

  static const Color surface = Color(0xFFFCF8FB);
  static const Color onSurface = Color(0xFF1B1B1D);
  static const Color surfaceDim = Color(0xFFDCD9DC);
  static const Color surfaceBright = Color(0xFFFCF8FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F5);
  static const Color surfaceContainer = Color(0xFFF0EDEF);
  static const Color surfaceContainerHigh = Color(0xFFEAE7EA);
  static const Color surfaceContainerHighest = Color(0xFFE4E2E4);
  static const Color surfaceVariant = Color(0xFFE4E2E4);
  static const Color onSurfaceVariant = Color(0xFF5A413D);

  static const Color inverseSurface = Color(0xFF303032);
  static const Color inverseOnSurface = Color(0xFFF3F0F2);

  static const Color background = Color(0xFFFCF8FB);
  static const Color onBackground = Color(0xFF1B1B1D);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color outline = Color(0xFF8E706C);
  static const Color outlineVariant = Color(0xFFE2BFB9);

  static const Color borderSubtle = Color(0xFFE5E5E7);
  static const Color surfaceGray = Color(0xFFFBFBFD);

  static const Color successGreen = Color(0xFF2D6A4F);
  static const Color statusPending = Color(0xFFF4A261);
  static const Color surfaceTint = Color(0xFFB22B1D);
}

class AppSpacing {
  AppSpacing._();

  static const double base = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double marginMobile = 20;
  static const double gutter = 16;
}

class AppTextStyles {
  AppTextStyles._();
}

ThemeData buildAppTheme() {
  const ColorScheme scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
    surfaceDim: AppColors.surfaceDim,
    surfaceBright: AppColors.surfaceBright,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    surfaceTint: AppColors.surfaceTint,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 32,
      height: 40 / 32,
      letterSpacing: -0.02 * 32,
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0.05 * 12,
      fontWeight: FontWeight.w600,
    ),
  ).apply(
    bodyColor: AppColors.onSurface,
    displayColor: AppColors.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surfaceGray,
    textTheme: textTheme,
    fontFamily: 'Inter',
    splashFactory: InkRipple.splashFactory,
  );
}