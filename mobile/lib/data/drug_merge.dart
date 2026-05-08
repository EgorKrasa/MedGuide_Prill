import '../models/drug.dart';
import '../utils/dosage_sort.dart';

String? _primaryActiveKey(Drug d) {
  if (d.activeSubstances.isEmpty) return null;
  final raw = d.activeSubstances.first.trim().toLowerCase();
  return raw.isEmpty ? null : raw;
}

List<Drug> mergeDrugsByPrimaryActiveSubstance(List<Drug> source) {
  if (source.length <= 1) return source;

  final buckets = <String, List<Drug>>{};
  final order = <String>[];

  for (final d in source) {
    final key = _primaryActiveKey(d) ?? '__single__:${d.id}';
    final list = buckets.putIfAbsent(key, () => <Drug>[]);
    if (list.isEmpty) order.add(key);
    list.add(d);
  }

  final out = <Drug>[];
  for (final key in order) {
    final group = buckets[key]!;
    if (key.startsWith('__single__:') || group.length == 1) {
      out.add(group.first);
      continue;
    }
    out.add(_mergeGroup(group));
  }
  return out;
}

Drug _mergeGroup(List<Drug> group) {
  group.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final base = group.first;

  final rows = <_DoseRow>[];
  final seen = <String>{};

  void addRow(String form, String dosage, double? price) {
    final f = form.trim();
    final d = dosage.trim();
    if (f.isEmpty && d.isEmpty) return;
    final line = [if (f.isNotEmpty) f, if (d.isNotEmpty) d].join(' • ');
    if (line.isEmpty || seen.contains(line)) return;
    seen.add(line);
    rows.add(_DoseRow(line: line, sortKey: dosageSortKey(d.isNotEmpty ? d : line), price: price));
  }

  for (final d in group) {
    final form0 = d.form.trim().isNotEmpty
        ? d.form.trim()
        : (d.formsAvailable.isNotEmpty ? d.formsAvailable.first.trim() : '');

    if (d.dosages.isNotEmpty) {
      for (var i = 0; i < d.dosages.length; i++) {
        final dose = d.dosages[i].trim();
        if (dose.isEmpty) continue;
        final price = i < d.pricesRub.length
            ? d.pricesRub[i]
            : (i == 0 ? d.priceRub : null);
        addRow(form0, dose, price);
      }
    } else {
      addRow(form0, d.dosage?.trim() ?? '', d.priceRub);
    }
  }

  rows.sort((a, b) => a.sortKey.compareTo(b.sortKey));

  final dosages = rows.map((r) => r.line).toList();
  final forms = <String>[];
  for (final d in group) {
    if (d.form.trim().isNotEmpty && !forms.contains(d.form.trim())) {
      forms.add(d.form.trim());
    }
    for (final f in d.formsAvailable) {
      if (f.trim().isNotEmpty && !forms.contains(f.trim())) {
        forms.add(f.trim());
      }
    }
  }

  final prescriptionRequired = group.any((d) => d.prescriptionRequired);
  final pregnancyContraindicated = group.any((d) => d.pregnancyContraindicated);

  int? minAge;
  for (final d in group) {
    final age = d.minAge;
    if (age == null) continue;
    final current = minAge;
    if (current == null || age < current) {
      minAge = age;
    }
  }

  final id = 'group:${base.activeSubstances.first.trim().toLowerCase()}';

  final alignedPrices = <double>[];
  var fallback = base.priceRub ?? 0;
  for (final r in rows) {
    final p = r.price ?? fallback;
    fallback = p;
    alignedPrices.add(p);
  }

  return Drug(
    id: id,
    name: _titleCaseRu(base.activeSubstances.first.trim()),
    form: forms.isNotEmpty ? forms.first : base.form,
    dosages: dosages,
    formsAvailable: forms,
    pricesRub: alignedPrices,
    dosage: dosages.isNotEmpty ? dosages.first : base.dosage,
    priceRub: alignedPrices.isNotEmpty ? alignedPrices.first : base.priceRub,
    minAge: minAge,
    pregnancyContraindicated: pregnancyContraindicated,
    prescriptionRequired: prescriptionRequired,
    activeSubstances: base.activeSubstances,
    indicationsSymptoms: _unionSymptoms(group),
    contraindications: _unionStrings(group.map((d) => d.contraindications)),
    chronicConditionWarnings: _unionStrings(group.map((d) => d.chronicConditionWarnings)),
    allergyWarnings: _unionStrings(group.map((d) => d.allergyWarnings)),
    sideEffects: _unionStrings(group.map((d) => d.sideEffects)),
    notes: _mergeClinicalNotes(group),
  );
}

class _DoseRow {
  final String line;
  final double sortKey;
  final double? price;

  _DoseRow({required this.line, required this.sortKey, this.price});
}

List<String> _unionSymptoms(List<Drug> group) {
  final out = <String>[];
  final seen = <String>{};
  for (final d in group) {
    for (final s in d.indicationsSymptoms) {
      final k = s.trim().toLowerCase();
      if (k.isEmpty || seen.contains(k)) continue;
      seen.add(k);
      out.add(s.trim());
    }
  }
  out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return out;
}

List<String> _unionStrings(Iterable<List<String>> lists) {
  final out = <String>[];
  final seen = <String>{};
  for (final list in lists) {
    for (final s in list) {
      final k = s.trim().toLowerCase();
      if (k.isEmpty || seen.contains(k)) continue;
      seen.add(k);
      out.add(s.trim());
    }
  }
  out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return out;
}

String? _mergeClinicalNotes(List<Drug> group) {
  final parts = <String>[];
  final seen = <String>{};
  for (final d in group) {
    final raw = d.notes?.trim();
    if (raw == null || raw.isEmpty) continue;
    for (final line in raw.split('\n')) {
      final t = line.trim();
      if (t.isEmpty || seen.contains(t)) continue;
      seen.add(t);
      parts.add(t);
    }
  }
  return parts.isEmpty ? null : parts.join('\n\n');
}

String _titleCaseRu(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
