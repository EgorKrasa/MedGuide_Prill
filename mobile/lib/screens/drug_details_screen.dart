import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../data/drug_repository.dart';
import '../models/drug.dart';
import '../theme/app_spacing.dart';
import '../utils/dosage_sort.dart';

class DrugDetailsScreen extends StatefulWidget {
  final Drug drug;
  final bool isFavorite;
  final Future<void> Function(String drugId) onToggleFavorite;

  const DrugDetailsScreen({
    super.key,
    required this.drug,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<DrugDetailsScreen> createState() => _DrugDetailsScreenState();
}

class _DrugDetailsScreenState extends State<DrugDetailsScreen> {
  final _repo = DrugRepository();
  List<Drug> _analogs = const <Drug>[];
  bool _loadingAnalogs = true;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _loadAnalogs();
  }

  Future<void> _loadAnalogs() async {
    if (widget.drug.id.startsWith('group:')) {
      if (!mounted) return;
      setState(() {
        _analogs = const <Drug>[];
        _loadingAnalogs = false;
      });
      return;
    }
    final values = await _repo.fetchAnalogs(widget.drug.id);
    if (!mounted) return;
    setState(() {
      _analogs = values;
      _loadingAnalogs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppSpacing.compactLayout(context);
    final canFavorite = !widget.drug.id.startsWith('group:');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.drug.name),
        actions: [
          if (compact && canFavorite)
            IconButton(
              onPressed: () async {
                await widget.onToggleFavorite(widget.drug.id);
                if (!mounted) return;
                setState(() => _isFavorite = !_isFavorite);
              },
              icon: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border),
            )
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.desktopContentMaxWidth),
          child: ListView(
            padding: AppSpacing.screenPaddingFor(context),
            children: [
              _HeaderCard(
                drug: widget.drug,
                isFavorite: _isFavorite,
                showInlineFavorite: !compact && canFavorite,
                onToggleFavorite: () async {
                  await widget.onToggleFavorite(widget.drug.id);
                  if (!mounted) return;
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
              if (widget.drug.prescriptionRequired) ...[
                SizedBox(height: AppSpacing.gap),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.prescriptionFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.prescriptionBorder, width: 2),
                  ),
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.gpp_bad_outlined, color: AppColors.prescriptionOnSurface),
                      title: Text(
                        'Требуется рецепт врача',
                        style: TextStyle(
                          color: AppColors.prescriptionOnSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        'Препарат отпускается по назначению специалиста.',
                        style: TextStyle(
                          color: AppColors.prescriptionOnSurface.withOpacity(0.92),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.gap),
              _SectionCard(
                title: 'Действующие вещества',
                items: widget.drug.activeSubstances,
                emptyText: 'Не указаны.',
                icon: Icons.science_outlined,
              ),
              SizedBox(height: AppSpacing.gap),
              _SectionCard(
                title: 'Параметры применения',
                items: [
                  if (widget.drug.minAge != null) 'Минимальный возраст: ${widget.drug.minAge}+',
                  if (widget.drug.pregnancyContraindicated) 'Противопоказан при беременности',
                ],
                emptyText: 'Ограничения не указаны.',
                icon: Icons.rule_folder_outlined,
              ),
              SizedBox(height: AppSpacing.gap),
              _SectionCard(
                title: 'Показания / симптомы',
                items: widget.drug.indicationsSymptoms,
                emptyText: 'Не указаны.',
                icon: Icons.fact_check_outlined,
              ),
              SizedBox(height: AppSpacing.gap),
              _SectionCard(
                title: 'Противопоказания',
                items: widget.drug.contraindications,
                emptyText: 'Не указаны.',
                icon: Icons.block_outlined,
              ),
              SizedBox(height: AppSpacing.gap),
              _SectionCard(
                title: 'Риски по хроническим болезням',
                items: widget.drug.chronicConditionWarnings,
                emptyText: 'Не указаны.',
                icon: Icons.medical_information_outlined,
              ),
              SizedBox(height: AppSpacing.gap),
              _SectionCard(
                title: 'Риски по аллергиям',
                items: widget.drug.allergyWarnings,
                emptyText: 'Не указаны.',
                icon: Icons.coronavirus_outlined,
              ),
              SizedBox(height: AppSpacing.gap),
              _SectionCard(
                title: 'Побочные эффекты',
                items: widget.drug.sideEffects,
                emptyText: 'Не указаны.',
                icon: Icons.health_and_safety_outlined,
              ),
              SizedBox(height: AppSpacing.gap),
              Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Аналоги', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (_loadingAnalogs)
                        const LinearProgressIndicator(minHeight: 3)
                      else if (_analogs.isEmpty)
                        const Text('Аналоги не найдены.')
                      else
                        ..._analogs.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• ${a.name} (${a.form})'),
                            )),
                    ],
                  ),
                ),
              ),
              if (widget.drug.notes != null && widget.drug.notes!.trim().isNotEmpty) ...[
                SizedBox(height: AppSpacing.gap),
                Card(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.info_outline),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(widget.drug.notes!)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Drug drug;
  final bool isFavorite;
  final bool showInlineFavorite;
  final Future<void> Function() onToggleFavorite;

  const _HeaderCard({
    required this.drug,
    required this.isFavorite,
    required this.showInlineFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final lines = _variantLines(drug);
    final summary = lines.isNotEmpty
        ? '${drug.form} (${lines.length} дозировки)'
        : [
            drug.form,
            if (drug.dosage != null) drug.dosage,
            if (drug.priceRub != null) '~${drug.priceRub!.round()} ₽',
          ].whereType<String>().join(' • ');
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titleBlock(context),
            const SizedBox(height: 12),
            desktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 230, child: _photoAndBuy(context)),
                      const SizedBox(width: 20),
                      Expanded(child: _metaAndBadges(context, summary, lines)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _photoAndBuy(context),
                      const SizedBox(height: 12),
                      _metaAndBadges(context, summary, lines),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _photoAndBuy(BuildContext context) {
    final price = drug.priceRub?.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: _DrugImageBox(
            drugId: drug.id,
            imageIndex: drug.imageIndex,
            imageUrl: drug.imageUrl,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          price != null ? 'от $price ₽' : 'Цена уточняется',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: null,
          child: const Text('Купить (скоро)'),
        ),
      ],
    );
  }

  Widget _titleBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(drug.name, style: Theme.of(context).textTheme.headlineSmall),
            ),
            if (showInlineFavorite)
              IconButton(
                tooltip: 'В избранное',
                onPressed: onToggleFavorite,
                icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
              ),
          ],
        ),
      ],
    );
  }

  Widget _metaAndBadges(BuildContext context, String summary, List<String> lines) {
    final actives = drug.activeSubstances.join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summary, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        if (lines.isNotEmpty) ...[
          ...lines.take(8).map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $line'),
                ),
              ),
          const SizedBox(height: 8),
        ],
        _kv('Форма выпуска', drug.form),
        _kv('Действующее вещество', actives.isNotEmpty ? actives : 'не указано'),
        _kv('Возраст', drug.minAge != null ? '${drug.minAge}+' : 'не указан'),
        SizedBox(height: AppSpacing.gapSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _MiniBadge(
              icon: Icons.verified_user_outlined,
              label: 'Проверка инструкции',
            ),
            _MiniBadge(
              icon: Icons.health_and_safety_outlined,
              label: 'Клинический режим',
            ),
          ],
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class _DrugImageBox extends StatelessWidget {
  final String drugId;
  final int? imageIndex;
  final String? imageUrl;

  const _DrugImageBox({
    required this.drugId,
    this.imageIndex,
    this.imageUrl,
  });

  static const _ext = ['jpg', 'jpeg', 'png', 'webp'];
  static const _defaultApiBase = String.fromEnvironment(
    'PRILL_API_URL',
    defaultValue: 'https://prill-api.onrender.com',
  );
  static Future<Set<String>>? _manifestAssetsFuture;
  static const Map<String, int> _indexById = {
    'парацетамол': 1,
    'ибупрофен': 2,
    'нимесулид': 3,
    'омепразол': 4,
    'панкреатин': 5,
    'амброксол': 6,
    'лоратадин': 7,
    'дротаверин': 8,
    'лоперамид': 9,
    'сертралин': 10,
    'флуоксетин': 11,
    'амитриптилин': 12,
    'диазепам': 13,
    'феназепам': 14,
    'кветиапин': 15,
    'венлафаксин': 16,
    'эсциталопрам': 17,
    'буспирон': 18,
    'тразодон': 19,
    'арипипразол': 20,
    'метформин': 21,
    'амоксициллин': 22,
    'азитромицин': 23,
    'цефтриаксон': 24,
    'левофлоксацин': 25,
    'кларитромицин': 26,
    'моксифлоксацин': 27,
    'фуросемид': 28,
    'спиронолактон': 29,
    'бисопролол': 30,
    'лозартан': 31,
    'амлодипин': 32,
    'эналаприл': 33,
    'рамиприл': 34,
    'аторвастатин': 35,
    'розувастатин': 36,
    'клопидогрел': 37,
    'ацетилсалициловаякислота': 38,
    'варфарин': 39,
    'ривароксабан': 40,
  };

  List<String> _candidates() {
    final idx = imageIndex ?? _indexById[drugId.trim().toLowerCase()];
    final out = <String>[];
    if (idx == null) return out;
    for (final e in _ext) {
      out.add('assets/images/drugs/$idx.$e');
      out.add('assets/images/$idx.$e');
    }
    return out;
  }

  Future<String?> _resolveAsset() async {
    final assets = await _knownAssets();
    for (final p in _candidates()) {
      if (assets.contains(p)) return p;
    }
    return null;
  }

  static Future<Set<String>> _knownAssets() {
    return _manifestAssetsFuture ??= () async {
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        return manifest.listAssets().toSet();
      } catch (_) {
        return <String>{};
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<String?>(
      future: _resolveAsset(),
      builder: (context, snap) {
        final asset = snap.data;
        final placeholder = Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 48, color: cs.primary),
              const SizedBox(height: 8),
              Text('Фото товара', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text('Скоро добавим', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );

        Widget fromAsset() {
          if (asset == null || asset.isEmpty) return placeholder;
          return Image.asset(
            asset,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          );
        }

        final remoteCandidates = _remoteCandidates();
        Widget content;
        if (remoteCandidates.isNotEmpty) {
          content = _networkWithFallback(
            urls: remoteCandidates,
            fallback: fromAsset(),
          );
        } else if (asset != null && asset.isNotEmpty) {
          content = fromAsset();
        } else {
          return placeholder;
        }

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: content,
            ),
          ),
        );
      },
    );
  }

  List<String> _remoteCandidates() {
    final out = <String>[];
    final seen = <String>{};
    final remote = imageUrl?.trim() ?? '';

    void add(String url) {
      final u = url.trim();
      if (u.isEmpty || seen.contains(u)) return;
      seen.add(u);
      out.add(u);
    }

    if (remote.isNotEmpty && !remote.contains('example.com')) {
      add(remote);
    }

    final idx = imageIndex ?? _indexById[drugId.trim().toLowerCase()];
    if (idx == null) return out;

    final base = _defaultApiBase.trim().replaceAll(RegExp(r'/$'), '');
    add('$base/media/drugs/$idx');
    for (final e in _ext) {
      add('$base/static/drugs/$idx.$e');
    }
    return out;
  }

  Widget _networkWithFallback({
    required List<String> urls,
    required Widget fallback,
    int index = 0,
  }) {
    if (index >= urls.length) return fallback;
    return Image.network(
      urls[index],
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return _networkWithFallback(
          urls: urls,
          fallback: fallback,
          index: index + 1,
        );
      },
    );
  }
}

List<String> _variantLines(Drug drug) {
  if (drug.dosages.isNotEmpty) {
    final out = <String>[];
    for (final i in dosageIndicesSorted(drug.dosages)) {
      final d = drug.dosages[i].trim();
      if (d.isEmpty) continue;
      final price = i < drug.pricesRub.length ? drug.pricesRub[i] : null;
      final p = price != null ? ' • ~${price.round()} ₽' : '';
      out.add('$d$p');
    }
    return out;
  }
  final bits = <String>[
    drug.form,
    if (drug.dosage != null) drug.dosage!,
    if (drug.priceRub != null) '~${drug.priceRub!.round()} ₽',
  ].where((s) => s.trim().isNotEmpty).toList();
  if (bits.isEmpty) return const <String>[];
  return [bits.join(' • ')];
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final String emptyText;
  final IconData icon;

  const _SectionCard({
    required this.title,
    required this.items,
    required this.emptyText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.gapSm),
            if (items.isEmpty)
              Text(emptyText)
            else
              ...items.map(
                (x) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(x)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
