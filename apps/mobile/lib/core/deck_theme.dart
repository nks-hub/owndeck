import 'package:flutter/material.dart';

import 'onboarding_theme.dart';

abstract final class DeckTheme {
  static const accent = Color(0xff167a72);
  static const cardRadius = 12.0;
  static const controlRadius = 12.0;

  static ThemeData light() => _create(Brightness.light);
  static ThemeData dark() => _create(Brightness.dark);

  static ThemeData _create(Brightness brightness) {
    final base = brightness == Brightness.light
        ? OnboardingTheme.light(seedColor: accent)
        : OnboardingTheme.dark(seedColor: accent);
    final colors = base.colorScheme;
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLowest,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: colors.onSurfaceVariant,
        titleTextStyle: base.textTheme.bodyLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
