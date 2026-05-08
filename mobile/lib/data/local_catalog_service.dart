import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/drug.dart';

class LocalCatalogService {
  LocalCatalogService._();
  static final LocalCatalogService instance = LocalCatalogService._();

  List<Drug> _all = const <Drug>[];
  var _loaded = false;

  List<Drug> get drugs => _all;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/drugs.json');
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      _all = const <Drug>[];
      _loaded = true;
      return;
    }
    _all = decoded
        .whereType<Map<String, dynamic>>()
        .map(Drug.fromAssetJson)
        .toList(growable: false);
    _loaded = true;
  }

  List<String> suggestSymptoms(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <String>[];
    final seen = <String>{};
    final out = <String>[];
    for (final d in _all) {
      for (final s in d.indicationsSymptoms) {
        final t = s.trim();
        if (t.isEmpty) continue;
        if (!t.toLowerCase().contains(q)) continue;
        final k = t.toLowerCase();
        if (seen.contains(k)) continue;
        seen.add(k);
        out.add(t);
      }
    }
    out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out.take(limit).toList(growable: false);
  }

  List<String> suggestActiveSubstances(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    final seen = <String>{};
    for (final d in _all) {
      for (final s in d.activeSubstances) {
        final t = s.trim();
        if (t.isEmpty) continue;
        if (q.isNotEmpty && !t.toLowerCase().contains(q)) continue;
        seen.add(_capitalizeFirst(t));
      }
    }
    final out = seen.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out.take(limit).toList(growable: false);
  }

  String _capitalizeFirst(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  List<String> suggestDrugNames(String query, {int limit = 12}) {
    final q = query.trim().toLowerCase();
    final names = _all.map((d) => d.name.trim()).where((s) => s.isNotEmpty).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (q.isEmpty) return names.take(limit).toList(growable: false);
    return names.where((n) => n.toLowerCase().contains(q)).take(limit).toList(growable: false);
  }

  List<Drug> searchBySymptoms(List<String> symptoms) {
    final want = symptoms.map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toSet();
    if (want.isEmpty) return const <Drug>[];
    final out = <Drug>[];
    for (final d in _all) {
      final have = d.indicationsSymptoms.map((s) => s.trim().toLowerCase()).toSet();
      if (want.every(have.contains)) {
        out.add(d);
      }
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  List<Drug> searchByMode({required String mode, required String query, int limit = 100}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <Drug>[];
    final out = <Drug>[];
    for (final d in _all) {
      if (mode == 'name') {
        if (d.name.toLowerCase().contains(q)) out.add(d);
      } else if (mode == 'active') {
        if (d.activeSubstances.any((s) => s.toLowerCase().contains(q))) out.add(d);
      } else {
        if (d.indicationsSymptoms.any((s) => s.toLowerCase().contains(q))) out.add(d);
      }
      if (out.length >= limit) break;
    }
    return out;
  }

  List<Drug> analogsFor(String drugId, {int limit = 10}) {
    Drug? drug;
    for (final e in _all) {
      if (e.id == drugId) {
        drug = e;
        break;
      }
    }
    if (drug == null) return const <Drug>[];
    final actives = drug.activeSubstances.map((e) => e.toLowerCase()).toSet();
    if (actives.isEmpty) return const <Drug>[];
    final out = <Drug>[];
    for (final c in _all) {
      if (c.id == drug.id) continue;
      if (c.form != drug.form) continue;
      final ca = c.activeSubstances.map((e) => e.toLowerCase()).toSet();
      if (ca.intersection(actives).isNotEmpty) {
        out.add(c);
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}
