/// Базовый URL API. Из `--dart-define=PRILL_API_URL=...` при сборке; иначе прод по умолчанию
/// (чтобы release APK без dart-define всё равно ходил в интернет).
class ApiConfig {
  ApiConfig._();

  static const String prodBaseUrl = 'https://prill-api.onrender.com';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('PRILL_API_URL', defaultValue: '');
    final trimmed = fromEnv.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return prodBaseUrl;
  }
}
