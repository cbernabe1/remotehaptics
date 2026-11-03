import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const fontFamily = 'Manrope';
  static const _seedColor = Color(0xFF6C63FF);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = _scheme(brightness);
    final baseTextTheme = ThemeData(brightness: brightness, useMaterial3: true)
        .textTheme
        .apply(
          fontFamily: fontFamily,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
    final textTheme = baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.05,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.4),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: isDark
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.7),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: isDark ? scheme.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.65),
        thickness: 1,
        space: 24,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
    );
  }

  static ColorScheme _scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? const Color(0xFFC1BDFF) : const Color(0xFF5647DD),
      onPrimary: isDark ? const Color(0xFF241B6B) : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF3B2F8F)
          : const Color(0xFFE6E2FF),
      onPrimaryContainer: isDark
          ? const Color(0xFFE6E2FF)
          : const Color(0xFF1C145C),
      secondary: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F9F8F),
      onSecondary: isDark ? const Color(0xFF003731) : Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF0D3F3A)
          : const Color(0xFFD3F8F1),
      onSecondaryContainer: isDark
          ? const Color(0xFFA7F3E8)
          : const Color(0xFF073A34),
      tertiary: isDark ? const Color(0xFFFFB59D) : const Color(0xFFE56B4B),
      onTertiary: isDark ? const Color(0xFF5A1C0B) : Colors.white,
      tertiaryContainer: isDark
          ? const Color(0xFF5B2B1F)
          : const Color(0xFFFFDBCF),
      onTertiaryContainer: isDark
          ? const Color(0xFFFFDBCF)
          : const Color(0xFF491405),
      surface: isDark ? const Color(0xFF0D0E1A) : const Color(0xFFF7F6FC),
      onSurface: isDark ? const Color(0xFFF3F1FF) : const Color(0xFF1B1A2B),
      onSurfaceVariant: isDark
          ? const Color(0xFFC7C3DF)
          : const Color(0xFF5E5A77),
      surfaceContainerLowest: isDark ? const Color(0xFF090A12) : Colors.white,
      surfaceContainerLow: isDark
          ? const Color(0xFF141525)
          : const Color(0xFFF1EFFA),
      surfaceContainer: isDark
          ? const Color(0xFF1A1B2E)
          : const Color(0xFFEAE7F6),
      surfaceContainerHigh: isDark
          ? const Color(0xFF22233A)
          : const Color(0xFFE2DEF2),
      surfaceContainerHighest: isDark
          ? const Color(0xFF2C2D47)
          : const Color(0xFFDAD5EE),
      outline: isDark ? const Color(0xFF928EAF) : const Color(0xFF7B7597),
      outlineVariant: isDark
          ? const Color(0xFF3D3C58)
          : const Color(0xFFD7D2E7),
      inverseSurface: isDark
          ? const Color(0xFFF3F1FF)
          : const Color(0xFF2E2C40),
      onInverseSurface: isDark
          ? const Color(0xFF1B1A2B)
          : const Color(0xFFF5F2FF),
    );
  }
}
