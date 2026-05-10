import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/drug.dart';
import 'api_cache_store.dart';
import 'local_catalog_service.dart';

class DrugRepository {
  DrugRepository({String? apiBaseUrl}) : _apiBaseUrl = apiBaseUrl ?? ApiConfig.baseUrl;

  final String _apiBaseUrl;
  final _cache = ApiCacheStore();
  static const _cacheTtl = Duration(hours: 24);

  bool get _remote => _apiBaseUrl.trim().isNotEmpty;

  String get _base => _apiBaseUrl.trim();

  Future<List<dynamic>?> _fetchListWithCache(Uri uri) async {
    final key = uri.toString();
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          await _cache.writeList(key, decoded);
          return decoded;
        }
      }
    } catch (_) {}
    return _cache.readList(key, maxAge: _cacheTtl);
  }

  Future<void> _ensureLocal() async {
    await LocalCatalogService.instance.ensureLoaded();
  }

  Future<List<String>> suggestSymptoms(String query, {int limit = 10}) async {
    if (!_remote) {
      await _ensureLocal();
      return LocalCatalogService.instance.suggestSymptoms(query, limit: limit);
    }
    final q = query.trim();
    if (q.isEmpty) return const <String>[];

    final uri = Uri.parse('$_base/symptoms').replace(
      queryParameters: <String, String>{
        'query': q,
        'limit': '$limit',
      },
    );
    final decoded = await _fetchListWithCache(uri);
    if (decoded == null) {
      await _ensureLocal();
      return LocalCatalogService.instance.suggestSymptoms(query, limit: limit);
    }

    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => m['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> suggestActiveSubstances(String query, {int limit = 12}) async {
    if (!_remote) {
      await _ensureLocal();
      return LocalCatalogService.instance.suggestActiveSubstances(query, limit: limit);
    }
    final q = query.trim();
    if (q.isEmpty) return const <String>[];

    final uri = Uri.parse('$_base/suggest/active').replace(
      queryParameters: <String, String>{
        'query': q,
        'limit': '$limit',
      },
    );
    final decoded = await _fetchListWithCache(uri);
    if (decoded == null) {
      await _ensureLocal();
      return LocalCatalogService.instance.suggestActiveSubstances(query, limit: limit);
    }
    return decoded.map((e) => e.toString()).where((s) => s.isNotEmpty).toList(growable: false);
  }

  Future<List<String>> suggestDrugNames(String query, {int limit = 12}) async {
    if (!_remote) {
      await _ensureLocal();
      return LocalCatalogService.instance.suggestDrugNames(query, limit: limit);
    }
    final q = query.trim();
    if (q.isEmpty) return const <String>[];

    final uri = Uri.parse('$_base/suggest/drug_name').replace(
      queryParameters: <String, String>{
        'query': q,
        'limit': '$limit',
      },
    );
    final decoded = await _fetchListWithCache(uri);
    if (decoded == null) {
      await _ensureLocal();
      return LocalCatalogService.instance.suggestDrugNames(query, limit: limit);
    }
    return decoded.map((e) => e.toString()).where((s) => s.isNotEmpty).toList(growable: false);
  }

  Future<List<Drug>> searchBySymptoms(List<String> symptoms) async {
    if (!_remote) {
      await _ensureLocal();
      return LocalCatalogService.instance.searchBySymptoms(symptoms);
    }
    final filtered = symptoms
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (filtered.isEmpty) return const <Drug>[];

    final query = filtered
        .map((s) => 'symptoms=${Uri.encodeQueryComponent(s)}')
        .join('&');
    final uri = Uri.parse('$_base/drugs?$query');
    final decoded = await _fetchListWithCache(uri);
    if (decoded == null) {
      await _ensureLocal();
      return LocalCatalogService.instance.searchBySymptoms(symptoms);
    }

    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => Drug.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  Future<List<Drug>> searchByMode({
    required String mode,
    required String query,
    int limit = 150,
  }) async {
    if (!_remote) {
      await _ensureLocal();
      return LocalCatalogService.instance.searchByMode(mode: mode, query: query, limit: limit);
    }
    final q = query.trim();
    if (q.isEmpty) return const <Drug>[];
    final uri = Uri.parse('$_base/drugs/search').replace(
      queryParameters: <String, String>{
        'mode': mode,
        'query': q,
        'limit': '$limit',
      },
    );
    final decoded = await _fetchListWithCache(uri);
    if (decoded == null) {
      await _ensureLocal();
      return LocalCatalogService.instance.searchByMode(mode: mode, query: query, limit: limit);
    }
    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => Drug.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }

  Future<List<Drug>> fetchAnalogs(String drugId, {int limit = 10}) async {
    if (!_remote) {
      await _ensureLocal();
      return LocalCatalogService.instance.analogsFor(drugId, limit: limit);
    }
    final uri = Uri.parse('$_base/drugs/$drugId/analogs').replace(
      queryParameters: <String, String>{'limit': '$limit'},
    );
    final decoded = await _fetchListWithCache(uri);
    if (decoded == null) {
      await _ensureLocal();
      return LocalCatalogService.instance.analogsFor(drugId, limit: limit);
    }
    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map((m) => Drug.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }
}
