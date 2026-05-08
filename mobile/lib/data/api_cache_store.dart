import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ApiCacheStore {
  static const _prefix = 'api_cache_v1:';

  Future<List<dynamic>?> readList(String key, {required Duration maxAge}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = int.tryParse(decoded['saved_at_ms']?.toString() ?? '');
      if (ts == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > maxAge.inMilliseconds) return null;
      final body = decoded['body'];
      if (body is List) return body;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeList(String key, List<dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(<String, dynamic>{
      'saved_at_ms': DateTime.now().millisecondsSinceEpoch,
      'body': body,
    });
    await prefs.setString('$_prefix$key', payload);
  }
}
