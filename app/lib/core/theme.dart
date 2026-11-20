import 'package:flutter/material.dart';

/// Dater's look: warm cream surfaces, coral accents, night-navy ink and
/// Plus Jakarta Sans. Colors are set by hand (no seed) so nothing drifts back
/// to Material's default palette.
abstract final class AppColors {
  static const coral = Color(0xFFFF6B4A);
  static const coralInk = Color(0xFFC2412A); // coral dark enough for text on cream
  static const navy = Color(0xFF2B2D42);
  static const peach = Color(0xFFFFD9CC);
  static const cream = Color(0xFFFBF6EF);
  static const mustard = Color(0xFFE9A23B);
}

abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static const _light = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.coral,
    // Navy on coral reads at ~5:1; white would be ~2.9:1.
    onPrimary: AppColors.navy,
    primaryContainer: AppColors.peach,
    onPrimaryContainer: Color(0xFF5A1A0C),
    secondary: AppColors.navy,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE4E3EC),
    onSecondaryContainer: AppColors.navy,
    tertiary: AppColors.mustard,
    onTertiary: AppColors.navy,
    tertiaryContainer: Color(0xFFFCE8C3),
    onTertiaryContainer: Color(0xFF4A3203),
    error: Color(0xFFD93A3A),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF5C0F0F),
    surface: AppColors.cream,
    onSurface: AppColors.navy,
    onSurfaceVariant: Color(0xFF6B6A75),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF7F0E6),
    surfaceContainer: Color(0xFFF3EADF),
    surfaceContainerHigh: Color(0xFFEEE3D6),
    surfaceContainerHighest: Color(0xFFE8DCCD),
    outline: Color(0xFFCFC1B1),
    outlineVariant: Color(0xFFEBE1D4),
    inverseSurface: AppColors.navy,
    onInverseSurface: AppColors.cream,
    inversePrimary: Color(0xFFFFB4A1),
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFF7A5C),
    onPrimary: Color(0xFF2A0F08),
    primaryContainer: Color(0xFF4A241C),
    onPrimaryContainer: AppColors.peach,
    secondary: Color(0xFFC9C8D9),
    onSecondary: AppColors.navy,
    secondaryContainer: Color(0xFF34364D),
    onSecondaryContainer: Color(0xFFE4E3EC),
    tertiary: Color(0xFFF2B95E),
    onTertiary: Color(0xFF3A2600),
    tertiaryContainer: Color(0xFF4F3A12),
    onTertiaryContainer: Color(0xFFFCE8C3),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF4A0B0B),
    errorContainer: Color(0xFF6B1A1A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF17171C),
    onSurface: Color(0xFFF3EEE8),
    onSurfaceVariant: Color(0xFFA9A6B0),
    surfaceContainerLowest: Color(0xFF121216),
    surfaceContainerLow: Color(0xFF1C1C22),
    surfaceContainer: Color(0xFF212128),
    surfaceContainerHigh: Color(0xFF2A2A32),
    surfaceContainerHighest: Color(0xFF33333C),
    outline: Color(0xFF4A4953),
    outlineVariant: Color(0xFF2E2E36),
    inverseSurface: Color(0xFFF3EEE8),
    onInverseSurface: AppColors.navy,
    inversePrimary: AppColors.coralInk,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  static ThemeData light() => _build(_light);
  static ThemeData dark() => _build(_dark);

  /// Coral that is readable as text on the background (links, text buttons).
  static Color ink(ColorScheme scheme) => scheme.brightness == Brightness.light ? AppColors.coralInk : scheme.primary;

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: fontFamily);
    final text = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: base.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
    );
    const pill = StadiumBorder();
    final rounded14 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final ink = AppTheme.ink(scheme);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall?.copyWith(color: scheme.onSurface, fontSize: 24),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? ink : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: scheme.primary, width: 3),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: pill,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ink, shape: pill, textStyle: text.labelLarge),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: pill,
        extendedTextStyle: text.labelLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.brightness == Brightness.light ? Colors.white : scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        floatingLabelStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        shape: pill,
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? scheme.primary : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.primary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 2),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
        actionTextColor: scheme.primary,
        shape: rounded14,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      badgeTheme: BadgeThemeData(backgroundColor: scheme.primary, textColor: scheme.onPrimary),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: Colors.transparent),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: rounded14,
      ),
    );
  }
}
