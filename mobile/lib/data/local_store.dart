import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/patient_profile.dart';

class LocalStore {
  static const _favoritesKey = 'favorites_drug_ids';
  static const _profileKey = 'patient_profile';

  Future<Set<String>> loadFavorites() async {
    final p = await SharedPreferences.getInstance();
    final values = p.getStringList(_favoritesKey) ?? const <String>[];
    return values.toSet();
  }

  Future<void> saveFavorites(Set<String> ids) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_favoritesKey, ids.toList()..sort());
  }

  Future<PatientProfile> loadProfile() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_profileKey);
    if (raw == null || raw.isEmpty) return const PatientProfile();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const PatientProfile();
    return PatientProfile.fromJson(decoded);
  }

  Future<void> saveProfile(PatientProfile profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}

