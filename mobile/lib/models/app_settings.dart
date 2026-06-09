import 'package:flutter/material.dart';

enum ThemePreference { system, light, dark }

class AppSettings {
  static const double minTextScale = 1.0;
  static const double maxTextScale = 1.35;
  static const double lowVisionTextScale = 1.32;

  final bool lowVisionMode;
  final double textScale;
  final ThemePreference themePreference;

  const AppSettings({
    this.lowVisionMode = false,
    this.textScale = 1.0,
    this.themePreference = ThemePreference.system,
  });

  double get effectiveTextScale => lowVisionMode ? lowVisionTextScale : textScale;

  ThemeMode get themeMode => switch (themePreference) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      };

  AppSettings copyWith({
    bool? lowVisionMode,
    double? textScale,
    ThemePreference? themePreference,
  }) {
    return AppSettings(
      lowVisionMode: lowVisionMode ?? this.lowVisionMode,
      textScale: textScale ?? this.textScale,
      themePreference: themePreference ?? this.themePreference,
    );
  }

  Map<String, dynamic> toJson() => {
        'lowVisionMode': lowVisionMode,
        'textScale': textScale,
        'themePreference': themePreference.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final prefName = json['themePreference'] as String? ?? 'system';
    final pref = ThemePreference.values.firstWhere(
      (e) => e.name == prefName,
      orElse: () => ThemePreference.system,
    );
    final scale = (json['textScale'] as num?)?.toDouble() ?? 1.0;
    return AppSettings(
      lowVisionMode: json['lowVisionMode'] as bool? ?? false,
      textScale: scale.clamp(minTextScale, maxTextScale),
      themePreference: pref,
    );
  }
}
