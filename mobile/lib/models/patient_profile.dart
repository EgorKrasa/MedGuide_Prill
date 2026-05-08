class PatientProfile {
  final int? age;
  final bool pregnant;
  final List<String> chronicConditions;
  final List<String> allergies;

  const PatientProfile({
    this.age,
    this.pregnant = false,
    this.chronicConditions = const <String>[],
    this.allergies = const <String>[],
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'age': age,
      'pregnant': pregnant,
      'chronicConditions': chronicConditions,
      'allergies': allergies,
    };
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      age: json['age'] is int ? json['age'] as int : null,
      pregnant: json['pregnant'] == true,
      chronicConditions: _read(json['chronicConditions']),
      allergies: _read(json['allergies']),
    );
  }

  static List<String> _read(dynamic v) {
    final list = v as List<dynamic>? ?? const <dynamic>[];
    return list.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList(growable: false);
  }
}

