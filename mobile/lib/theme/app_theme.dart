import 'package:flutter/material.dart';

import '../models/app_settings.dart';

const _seed = Color(0xFF1B8A5A);

ThemeData buildAppTheme(AppSettings settings, Brightness brightness) {
  final highContrast = settings.lowVisionMode;
  final colorScheme = highContrast
      ? (brightness == Brightness.light
          ? ColorScheme.highContrastLight(primary: _seed)
          : ColorScheme.highContrastDark(primary: _seed))
      : ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    scaffoldBackgroundColor: highContrast
        ? colorScheme.surface
        : (brightness == Brightness.light ? const Color(0xFFF3F7F5) : null),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: highContrast ? 24 : 22,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(highContrast ? 12 : 20),
        side: BorderSide(
          color: colorScheme.outline,
          width: highContrast ? 2 : 1,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline, width: highContrast ? 2 : 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.outline, width: highContrast ? 2 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: highContrast ? 2.4 : 1.8),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: highContrast ? 18 : 14,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: colorScheme.outline, width: highContrast ? 1.5 : 1),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: highContrast ? 16 : 14,
        color: colorScheme.onSurface,
      ),
      backgroundColor: colorScheme.surface,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(highContrast ? 56 : 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: highContrast ? 17 : 15,
        ),
        overlayColor: Colors.transparent,
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: highContrast ? 14 : 10,
      ),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: highContrast ? 18 : 16,
        color: colorScheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: highContrast ? 15 : 14,
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      height: highContrast ? 72 : 64,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          fontSize: highContrast ? 14 : 12,
          color: states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.all(null),
    ),
  );

  if (!highContrast) return base;

  return base.copyWith(
    textTheme: _scaledTextTheme(base.textTheme, 1.08),
  );
}

TextTheme _scaledTextTheme(TextTheme theme, double factor) {
  TextStyle? s(TextStyle? t) {
    if (t == null) return null;
    return t.copyWith(
      fontSize: (t.fontSize ?? 14) * factor,
      fontWeight: FontWeight.lerp(t.fontWeight, FontWeight.w700, 0.35),
    );
  }

  return TextTheme(
    displayLarge: s(theme.displayLarge),
    displayMedium: s(theme.displayMedium),
    displaySmall: s(theme.displaySmall),
    headlineLarge: s(theme.headlineLarge),
    headlineMedium: s(theme.headlineMedium),
    headlineSmall: s(theme.headlineSmall),
    titleLarge: s(theme.titleLarge),
    titleMedium: s(theme.titleMedium),
    titleSmall: s(theme.titleSmall),
    bodyLarge: s(theme.bodyLarge),
    bodyMedium: s(theme.bodyMedium),
    bodySmall: s(theme.bodySmall),
    labelLarge: s(theme.labelLarge),
    labelMedium: s(theme.labelMedium),
    labelSmall: s(theme.labelSmall),
  );
}
