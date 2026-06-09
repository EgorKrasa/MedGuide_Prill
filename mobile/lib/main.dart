import 'package:flutter/material.dart';

import 'data/app_settings_store.dart';
import 'data/local_catalog_service.dart';
import 'models/app_settings.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalCatalogService.instance.ensureLoaded();
  final settings = await AppSettingsStore().load();
  runApp(PrillApp(initialSettings: settings));
}

class PrillApp extends StatefulWidget {
  const PrillApp({super.key, required this.initialSettings});

  final AppSettings initialSettings;

  @override
  State<PrillApp> createState() => _PrillAppState();
}

class _PrillAppState extends State<PrillApp> {
  late AppSettings _settings;
  final _settingsStore = AppSettingsStore();

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  Future<void> _updateSettings(AppSettings next) async {
    setState(() => _settings = next);
    await _settingsStore.save(next);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Справочник лекарств',
      theme: buildAppTheme(_settings, Brightness.light),
      darkTheme: buildAppTheme(_settings, Brightness.dark),
      themeMode: _settings.themeMode,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(_settings.effectiveTextScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: HomeScreen(
        settings: _settings,
        onSettingsChanged: _updateSettings,
      ),
    );
  }
}
