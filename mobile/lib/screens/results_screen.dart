import 'package:flutter/material.dart';

import '../models/drug.dart';
import '../theme/app_spacing.dart';
import '../utils/dosage_sort.dart';
import 'drug_details_screen.dart';

class ResultsScreen extends StatelessWidget {
  final List<String> symptoms;
  final List<Drug> results;
  final Set<String> favorites;
  final Future<void> Function(String drugId) onToggleFavorite;

  const ResultsScreen({
    super.key,
    required this.symptoms,
    required this.results,
    required this.favorites,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSymptoms = symptoms
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты подбора'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.desktopContentMaxWidth),
          child: ListView(
            padding: AppSpacing.screenPaddingFor(context),
            children: [
              Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibleSymptoms.isNotEmpty) ...[
                        Text(
                          'Симптомы',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in visibleSymptoms)
                              Chip(
                                label: Text(
                                  s,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text('Количество препаратов: ${results.length}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.gap),
              if (results.isEmpty)
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Text(
                      visibleSymptoms.isNotEmpty
                          ? 'По выбранным симптомам ничего не найдено. Попробуй сформулировать иначе или добавь/удали симптом.'
                          : 'Ничего не найдено. Измени запрос и повтори поиск.',
                    ),
                  ),
                )
              else
                ...[
                  for (var i = 0; i < results.length; i++) ...[
                    if (i > 0) SizedBox(height: AppSpacing.gap),
                    _ResultDrugCard(
                      drug: results[i],
                      isFavorite: _isFavoriteDrug(results[i], favorites),
                      onToggleFavorite: onToggleFavorite,
                    ),
                  ],
                ],
            ],
          ),
        ),
      ),
    );
  }
}

String _listSubtitle(Drug d) {
  if (d.dosages.isNotEmpty) {
    final order = dosageIndicesSorted(d.dosages);
    final sorted = order.map((i) => d.dosages[i]).toList();
    final head = sorted.take(3).join(' · ');
    final tail = sorted.length > 3 ? ' · …' : '';
    return '$head$tail';
  }
  return [
    d.form,
    if (d.dosage != null) d.dosage,
    if (d.priceRub != null) '~${d.priceRub!.round()} ₽',
  ].whereType<String>().join(' • ');
}

bool _isFavoriteDrug(Drug d, Set<String> favorites) {
  final idKey = d.id.trim().toLowerCase();
  if (favorites.contains(idKey)) return true;
  if (d.activeSubstances.isEmpty) return false;
  final active = d.activeSubstances.first.trim().toLowerCase();
  if (active.isEmpty) return false;
  return favorites.contains('group:$active');
}

class _ResultDrugCard extends StatelessWidget {
  final Drug drug;
  final bool isFavorite;
  final Future<void> Function(String drugId) onToggleFavorite;

  const _ResultDrugCard({
    required this.drug,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.medication_outlined),
      ),
      title: Text(drug.name),
      subtitle: Text(_listSubtitle(drug)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (drug.prescriptionRequired) ...[
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: const Text(
                'Рецепт',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DrugDetailsScreen(
              drug: drug,
              isFavorite: isFavorite,
              onToggleFavorite: onToggleFavorite,
            ),
          ),
        );
      },
    );
    return Card(child: tile);
  }
}
