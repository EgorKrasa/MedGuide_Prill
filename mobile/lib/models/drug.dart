class Drug {
  final String id;
  final String name;
  final int? imageIndex;
  final String? imageUrl;
  final String form;
  final String? dosage;
  final List<String> dosages;
  final List<String> formsAvailable;
  final List<double> pricesRub;
  final double? priceRub;
  final int? minAge;
  final bool pregnancyContraindicated;
  final bool prescriptionRequired;
  final List<String> activeSubstances;
  final List<String> indicationsSymptoms;
  final List<String> contraindications;
  final List<String> chronicConditionWarnings;
  final List<String> allergyWarnings;
  final List<String> sideEffects;
  final String? notes;

  const Drug({
    required this.id,
    required this.name,
    this.imageIndex,
    this.imageUrl,
    required this.form,
    required this.dosages,
    required this.formsAvailable,
    required this.pricesRub,
    required this.activeSubstances,
    required this.indicationsSymptoms,
    required this.contraindications,
    required this.chronicConditionWarnings,
    required this.allergyWarnings,
    required this.sideEffects,
    this.dosage,
    this.priceRub,
    this.minAge,
    this.pregnancyContraindicated = false,
    this.prescriptionRequired = false,
    this.notes,
  });

  factory Drug.fromJson(Map<String, dynamic> json) {
    final rawSymptoms = json['symptoms'] as List<dynamic>? ?? const <dynamic>[];
    final indications = rawSymptoms
        .whereType<Map<String, dynamic>>()
        .map((m) => m['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    return Drug(
      id: json['id'] as String,
      name: json['name'] as String,
      imageIndex: _readInt(json['image_index']),
      imageUrl: json['image_url'] as String?,
      form: json['form'] as String,
      dosage: json['dosage'] as String?,
      dosages: _readStringList(json['dosages']),
      formsAvailable: _readStringList(json['forms_available']),
      pricesRub: _readDoubleList(json['prices_rub']),
      priceRub: _readPrice(json['price_rub']),
      minAge: _readInt(json['min_age']),
      pregnancyContraindicated: json['pregnancy_contraindicated'] == true,
      prescriptionRequired: json['prescription_required'] == true,
      activeSubstances: _readStringList(json['active_substances']),
      indicationsSymptoms: indications,
      contraindications: _readStringList(json['contraindications']),
      chronicConditionWarnings: _readStringList(json['chronic_condition_warnings']),
      allergyWarnings: _readStringList(json['allergy_warnings']),
      sideEffects: _readStringList(json['side_effects']),
      notes: json['notes'] as String?,
    );
  }

  factory Drug.fromAssetJson(Map<String, dynamic> json) {
    return Drug(
      id: json['id'] as String,
      name: json['name'] as String,
      imageIndex: _readInt(json['imageIndex']),
      imageUrl: json['imageUrl'] as String?,
      form: json['form'] as String,
      dosage: json['dosage'] as String?,
      dosages: _readStringList(json['dosages']),
      formsAvailable: _readStringList(json['formsAvailable']),
      pricesRub: _readDoubleList(json['pricesRub']),
      priceRub: _readPrice(json['priceRub']),
      minAge: _readInt(json['minAge']),
      pregnancyContraindicated: json['pregnancyContraindicated'] == true,
      prescriptionRequired: json['prescriptionRequired'] == true,
      activeSubstances: _readStringList(json['activeSubstances']),
      indicationsSymptoms: _readStringList(json['indicationsSymptoms']),
      contraindications: _readStringList(json['contraindications']),
      chronicConditionWarnings: _readStringList(json['chronicConditionWarnings']),
      allergyWarnings: _readStringList(json['allergyWarnings']),
      sideEffects: _readStringList(json['sideEffects']),
      notes: json['notes'] as String?,
    );
  }

  static List<String> _readStringList(dynamic value) {
    final list = (value as List<dynamic>? ?? const <dynamic>[]);
    return list.map((e) => e.toString()).toList(growable: false);
  }

  static double? _readPrice(dynamic value) {
    if (value == null) return null;
    final s = value.toString().replaceAll(',', '.');
    return double.tryParse(s);
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static List<double> _readDoubleList(dynamic value) {
    final list = (value as List<dynamic>? ?? const <dynamic>[]);
    final out = <double>[];
    for (final e in list) {
      final p = _readPrice(e);
      if (p != null) out.add(p);
    }
    return out;
  }
}
