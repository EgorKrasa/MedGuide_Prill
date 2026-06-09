import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../theme/app_spacing.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPaddingFor(context),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Доступность', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Крупный текст и высокий контраст для комфортного чтения.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Режим для слабовидящих'),
                    subtitle: const Text('Крупный шрифт и контрастное оформление'),
                    value: settings.lowVisionMode,
                    onChanged: (v) => onChanged(settings.copyWith(lowVisionMode: v)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.gap),
          if (!settings.lowVisionMode)
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Размер текста', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      _textScaleLabel(settings.textScale),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Slider(
                      value: settings.textScale,
                      min: AppSettings.minTextScale,
                      max: AppSettings.maxTextScale,
                      divisions: 7,
                      label: _textScaleLabel(settings.textScale),
                      onChanged: (v) => onChanged(settings.copyWith(textScale: v)),
                    ),
                  ],
                ),
              ),
            ),
          if (!settings.lowVisionMode) SizedBox(height: AppSpacing.gap),
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Тема оформления', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemePreference>(
                    segments: const [
                      ButtonSegment(
                        value: ThemePreference.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Светлая'),
                      ),
                      ButtonSegment(
                        value: ThemePreference.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Тёмная'),
                      ),
                      ButtonSegment(
                        value: ThemePreference.system,
                        icon: Icon(Icons.settings_brightness_outlined),
                        label: Text('Система'),
                      ),
                    ],
                    selected: {settings.themePreference},
                    onSelectionChanged: (s) => onChanged(settings.copyWith(themePreference: s.first)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _textScaleLabel(double scale) {
    if (scale <= 1.05) return 'Обычный';
    if (scale <= 1.15) return 'Чуть крупнее';
    if (scale <= 1.22) return 'Крупный';
    if (scale <= 1.29) return 'Очень крупный';
    return 'Максимальный';
  }
}
