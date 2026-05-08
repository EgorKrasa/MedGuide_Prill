double dosageSortKey(String s) {
  final m = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(s.replaceAll(',', '.'));
  if (m == null) return 0;
  return double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
}

List<int> dosageIndicesSorted(List<String> dosages) {
  final idx = List<int>.generate(dosages.length, (i) => i);
  idx.sort((a, b) => dosageSortKey(dosages[a]).compareTo(dosageSortKey(dosages[b])));
  return idx;
}
