import 'package:flutter/material.dart';

import '../data/drug_merge.dart';
import '../data/local_catalog_service.dart';
import '../data/drug_repository.dart';
import '../data/local_store.dart';
import '../models/drug.dart';
import '../models/patient_profile.dart';
import '../theme/app_spacing.dart';
import 'drug_details_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = DrugRepository();
  final _store = LocalStore();
  final _controller = TextEditingController();
  final _activeController = TextEditingController();
  final _nameController = TextEditingController();
  final _favoritesSearchController = TextEditingController();

  String? _error;
  PatientProfile _profile = const PatientProfile();
  Set<String> _favorites = <String>{};
  String _searchMode = 'symptom';

  final List<String> _selectedSymptoms = <String>[];
  List<String> _suggestions = const <String>[];
  bool _loadingSuggestions = false;
  bool _searching = false;
  int _suggestionRequestId = 0;
  int _mobileTab = 0;
  int _desktopTab = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    _activeController.addListener(_onQueryChanged);
    _nameController.addListener(_onQueryChanged);
    _favoritesSearchController.addListener(() => setState(() {}));
    _initLocalData();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onQueryChanged)
      ..dispose();
    _activeController
      ..removeListener(_onQueryChanged)
      ..dispose();
    _nameController
      ..removeListener(_onQueryChanged)
      ..dispose();
    _favoritesSearchController.dispose();
    super.dispose();
  }

  Future<void> _initLocalData() async {
    final profile = await _store.loadProfile();
    final favorites = await _store.loadFavorites();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _favorites = favorites.map((e) => e.trim().toLowerCase()).toSet();
    });
  }

  void _onQueryChanged() {
    final text = _currentTextController().text;
    _loadSuggestions(text);
  }

  void _addSymptom(String symptom) {
    final s = symptom.trim();
    if (s.isEmpty) return;
    if (_selectedSymptoms.contains(s)) return;
    setState(() {
      _selectedSymptoms.add(s);
      _controller.clear();
      _suggestions = const <String>[];
    });
  }

  void _pickSuggestion(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    if (_searchMode == 'symptom') {
      _addSymptom(v);
      return;
    }
    final ctl = _currentTextController();
    setState(() {
      ctl.text = v;
      ctl.selection = TextSelection.collapsed(offset: v.length);
    });
    _loadSuggestions(v);
  }

  void _changeSearchMode(String mode) {
    if (_searchMode == mode) return;
    setState(() {
      _searchMode = mode;
      _suggestions = const <String>[];
      _loadingSuggestions = false;
    });
    _onQueryChanged();
  }

  void _removeSymptom(String symptom) {
    setState(() {
      _selectedSymptoms.remove(symptom);
    });
  }

  Future<void> _loadSuggestions(String query) async {
    final currentId = ++_suggestionRequestId;
    final text = query.trim();
    if (text.isEmpty) {
      setState(() {
        _suggestions = const <String>[];
      });
      return;
    }

    setState(() {
      _loadingSuggestions = true;
    });

    try {
      late final List<String> items;
      if (_searchMode == 'symptom') {
        items = await _repo.suggestSymptoms(text, limit: 12);
      } else if (_searchMode == 'active') {
        items = await _repo.suggestActiveSubstances(text, limit: 12);
      } else {
        items = await _repo.suggestDrugNames(text, limit: 12);
      }
      if (!mounted || currentId != _suggestionRequestId) return;
      setState(() {
        _suggestions = items;
        _error = null;
      });
    } catch (e) {
      if (!mounted || currentId != _suggestionRequestId) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted || currentId != _suggestionRequestId) return;
      setState(() {
        _loadingSuggestions = false;
      });
    }
  }

  Future<void> _openResults() async {
    final mode = _searchMode;
    final freeQuery = _currentTextController().text.trim();
    if (mode == 'symptom' && _selectedSymptoms.isEmpty) return;
    if (mode != 'symptom' && freeQuery.isEmpty) return;

    setState(() {
      _searching = true;
    });

    try {
      List<Drug> results;
      if (mode == 'symptom') {
        results = await _repo.searchBySymptoms(_selectedSymptoms);
      } else {
        results = await _repo.searchByMode(mode: mode, query: freeQuery);
      }
      results = mergeDrugsByPrimaryActiveSubstance(results);
      final filtered = _applyProfileFilter(results);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            symptoms: List.unmodifiable(_selectedSymptoms),
            results: filtered,
            favorites: _favorites,
            onToggleFavorite: _toggleFavorite,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppSpacing.compactLayout(context);
    final canSearch = !_searching &&
        ((_searchMode == 'symptom' && _selectedSymptoms.isNotEmpty) ||
            (_searchMode != 'symptom' && _currentTextController().text.trim().isNotEmpty));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          compact
              ? (_mobileTab == 0
                  ? 'Поиск'
                  : _mobileTab == 1
                      ? 'Избранное'
                      : 'Профиль')
              : 'Клинический справочник',
        ),
        actions: compact ? const [] : _desktopTopTabs(colors),
      ),
      body: compact
          ? IndexedStack(
              index: _mobileTab,
              children: [
                _buildSearchTab(context, canSearch, colors),
                _buildFavoritesTab(context),
                _buildProfileTab(context),
              ],
            )
          : IndexedStack(
              index: _desktopTab,
              children: [
                _buildDesktopShell(_buildSearchTab(context, canSearch, colors)),
                _buildDesktopShell(_buildFavoritesTab(context)),
                _buildDesktopShell(_buildProfileTab(context)),
              ],
            ),
      bottomNavigationBar: compact
          ? NavigationBar(
              animationDuration: Duration.zero,
              selectedIndex: _mobileTab,
              onDestinationSelected: (index) => setState(() => _mobileTab = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  label: 'Поиск',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bookmark_border_rounded),
                  selectedIcon: Icon(Icons.bookmark_rounded),
                  label: 'Избранное',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Профиль',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildDesktopShell(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.desktopContentMaxWidth),
        child: child,
      ),
    );
  }

  List<Widget> _desktopTopTabs(ColorScheme colors) {
    Widget tab(int idx, IconData icon, String label) {
      final selected = _desktopTab == idx;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.transparent : colors.outlineVariant,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              onTap: () => setState(() => _desktopTab = idx),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: selected ? colors.primary : colors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? colors.primary : colors.onSurfaceVariant,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return [
      tab(0, Icons.search_rounded, 'Поиск'),
      tab(1, Icons.bookmark_border_rounded, 'Избранное'),
      tab(2, Icons.person_outline, 'Профиль'),
    ];
  }

  Widget _buildSearchTab(BuildContext context, bool canSearch, ColorScheme colors) {
    return Padding(
      padding: AppSpacing.screenPaddingFor(context),
      child: ListView(
        children: [
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colors.primaryContainer.withOpacity(0.6),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: colors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Поиск препаратов по симптомам',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Используйте 2–3 симптома для более точной выборки.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.gapSm + 2),
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Параметры запроса', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: AppSpacing.gapSm),
                  TextField(
                    controller: _currentTextController(),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (v) {
                      if (_searchMode == 'symptom') {
                        _addSymptom(v);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: _searchMode == 'symptom'
                          ? 'например: кашель, температура'
                          : _searchMode == 'active'
                              ? 'например: сертралин'
                              : 'например: ибупрофен',
                      prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                      suffixIcon: IconButton(
                        tooltip: _searchMode == 'symptom' ? 'Добавить симптом' : 'Очистить',
                        onPressed: () {
                          if (_searchMode == 'symptom') {
                            _addSymptom(_controller.text);
                          } else {
                            _currentTextController().clear();
                            setState(() {});
                          }
                        },
                        icon: Icon(_searchMode == 'symptom' ? Icons.add : Icons.clear),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.gapSm),
                  _buildSearchModeSelector(colors),
                  if (_loadingSuggestions) ...[
                    SizedBox(height: AppSpacing.gapSm),
                    const LinearProgressIndicator(minHeight: 3),
                  ] else if (_suggestions.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.gapSm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _suggestions)
                          ActionChip(
                            label: Text(s),
                            onPressed: () => _pickSuggestion(s),
                          ),
                      ],
                    ),
                  ],
                  SizedBox(height: AppSpacing.gap),
                  if (_searchMode == 'symptom' && _selectedSymptoms.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _selectedSymptoms)
                          InputChip(
                            label: Text(s),
                            onDeleted: () => _removeSymptom(s),
                          ),
                      ],
                    )
                  else if (_searchMode == 'symptom')
                    Text(
                      'Симптомы не выбраны.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (_searchMode != 'symptom' && _currentTextController().text.trim().isEmpty)
                    Text(
                      _searchMode == 'active'
                          ? 'Вещество не введено.'
                          : 'Название не введено.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  SizedBox(height: AppSpacing.gapSm + 2),
                  FilledButton.icon(
                    onPressed: canSearch ? _openResults : null,
                    icon: const Icon(Icons.manage_search_rounded),
                    label: _searching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Выполнить поиск'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.gap),
          _buildStatus(context),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(BuildContext context) {
    final all = LocalCatalogService.instance.drugs;
    final search = _favoritesSearchController.text.trim().toLowerCase();
    final values = all.where(_isFavoriteDrug).where((d) {
      if (search.isEmpty) return true;
      final inName = d.name.toLowerCase().contains(search);
      final inActives = d.activeSubstances.any((a) => a.toLowerCase().contains(search));
      return inName || inActives;
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Padding(
      padding: AppSpacing.screenPaddingFor(context),
      child: Column(
        children: [
          TextField(
            controller: _favoritesSearchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Поиск в избранном',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _favoritesSearchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистить',
                      onPressed: _favoritesSearchController.clear,
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
          ),
          SizedBox(height: AppSpacing.gap),
          Expanded(
            child: values.isEmpty
                ? Center(
                    child: Text(
                      search.isEmpty
                          ? 'Пока пусто. Добавь препараты в избранное из карточки.'
                          : 'Ничего не найдено.',
                    ),
                  )
                : ListView.separated(
                    itemCount: values.length,
                    separatorBuilder: (_, __) => SizedBox(height: AppSpacing.gap),
                    itemBuilder: (context, index) {
                      final d = values[index];
                      final tile = ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.medication_outlined),
                        ),
                        title: Text(d.name),
                        subtitle: Text([d.form, if (d.dosage != null) d.dosage].join(' • ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (d.prescriptionRequired)
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
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DrugDetailsScreen(
                                drug: d,
                                isFavorite: _isFavoriteDrug(d),
                                onToggleFavorite: _toggleFavorite,
                              ),
                            ),
                          );
                        },
                      );
                      return Card(child: tile);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPaddingFor(context),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Профиль пациента', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: AppSpacing.gap),
                  Text('Возраст: ${_profile.age?.toString() ?? 'не указан'}'),
                  const SizedBox(height: 6),
                  Text('Беременность: ${_profile.pregnant ? 'да' : 'нет'}'),
                  const SizedBox(height: 6),
                  Text(
                    'Хронические болезни: '
                    '${_profile.chronicConditions.isEmpty ? 'не указаны' : _profile.chronicConditions.join(', ')}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Аллергии: ${_profile.allergies.isEmpty ? 'не указаны' : _profile.allergies.join(', ')}',
                  ),
                  SizedBox(height: AppSpacing.gap),
                  FilledButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Изменить профиль'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchModeSelector(ColorScheme colors) {
    Widget row(String value, String title, IconData icon) {
      final selected = _searchMode == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: selected ? colors.primaryContainer.withOpacity(0.9) : colors.surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            onTap: () => _changeSearchMode(value),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? Colors.transparent : colors.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: selected ? colors.primary : colors.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (selected) Icon(Icons.check_rounded, color: colors.primary),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!AppSpacing.compactLayout(context)) {
      return Row(
        children: [
          Expanded(child: row('symptom', 'По симптомам', Icons.healing_outlined)),
          const SizedBox(width: 8),
          Expanded(child: row('active', 'По веществу', Icons.science_outlined)),
          const SizedBox(width: 8),
          Expanded(child: row('name', 'По названию', Icons.medication_outlined)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row('symptom', 'По симптомам', Icons.healing_outlined),
        row('active', 'По веществу', Icons.science_outlined),
        row('name', 'По названию', Icons.medication_outlined),
      ],
    );
  }

  Widget _buildStatus(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          'Ошибка: $_error',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.tips_and_updates_outlined),
            title: const Text('Подсказка'),
            subtitle: const Text('Запрос с 2–3 симптомами повышает релевантность результата.'),
          ),
        ),
        SizedBox(height: AppSpacing.gapSm),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark_outline),
            title: const Text('Избранное'),
            subtitle: Text('Сохранено препаратов: ${_favorites.length}'),
          ),
        ),
        SizedBox(height: AppSpacing.gapSm),
        const Card(
          child: ListTile(
            leading: Icon(Icons.warning_amber_rounded),
            title: Text('Важно'),
            subtitle: Text(
              'Приложение учебное. Перед применением лекарств обязательно консультируйся с врачом и читай официальную инструкцию.',
            ),
          ),
        ),
      ],
    );
  }

  List<Drug> _applyProfileFilter(List<Drug> source) {
    final age = _profile.age;
    final chronic = _profile.chronicConditions.map((e) => e.toLowerCase()).toList();
    final allergies = _profile.allergies.map((e) => e.toLowerCase()).toList();
    final filtered = <Drug>[];
    for (final d in source) {
      if (age != null && d.minAge != null && age < d.minAge!) continue;
      if (_profile.pregnant && d.pregnancyContraindicated) continue;
      if (d.chronicConditionWarnings.any((w) => chronic.any((c) => w.toLowerCase().contains(c)))) {
        continue;
      }
      if (d.allergyWarnings.any((w) => allergies.any((a) => w.toLowerCase().contains(a)))) {
        continue;
      }
      filtered.add(d);
    }
    return filtered;
  }

  Future<void> _toggleFavorite(String drugId) async {
    final normalized = _normalizeFavoriteKey(drugId);
    final next = {..._favorites};
    if (next.contains(normalized)) {
      next.remove(normalized);
    } else {
      next.add(normalized);
    }
    await _store.saveFavorites(next);
    final reloaded = await _store.loadFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = reloaded;
    });
  }

  Future<void> _editProfile() async {
    final ageCtl = TextEditingController(text: _profile.age?.toString() ?? '');
    final chronicCtl = TextEditingController(text: _profile.chronicConditions.join(', '));
    final allergyCtl = TextEditingController(text: _profile.allergies.join(', '));
    var pregnant = _profile.pregnant;

    Widget form(BuildContext context, void Function(void Function()) setSheetState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Профиль пациента', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(controller: ageCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Возраст')),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Беременность'),
            value: pregnant,
            onChanged: (v) => setSheetState(() => pregnant = v),
          ),
          TextField(
            controller: chronicCtl,
            decoration: const InputDecoration(labelText: 'Хронические болезни (через запятую)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: allergyCtl,
            decoration: const InputDecoration(labelText: 'Аллергии (через запятую)'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final profile = PatientProfile(
                age: int.tryParse(ageCtl.text.trim()),
                pregnant: pregnant,
                chronicConditions: _splitCsv(chronicCtl.text),
                allergies: _splitCsv(allergyCtl.text),
              );
              await _store.saveProfile(profile);
              final reloaded = await _store.loadProfile();
              if (!mounted) return;
              setState(() => _profile = reloaded);
              Navigator.pop(context);
            },
            child: const Text('Сохранить профиль'),
          ),
        ],
      );
    }

    if (AppSpacing.compactLayout(context)) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) => form(context, setSheetState),
            ),
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setSheetState) => form(context, setSheetState),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static List<String> _splitCsv(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  TextEditingController _currentTextController() {
    if (_searchMode == 'symptom') return _controller;
    if (_searchMode == 'active') return _activeController;
    return _nameController;
  }

  String _normalizeFavoriteKey(String id) {
    final raw = id.trim().toLowerCase();
    if (raw.startsWith('group:')) return raw;
    return raw;
  }

  String _groupKeyForDrug(Drug d) {
    if (d.activeSubstances.isEmpty) return d.id.trim().toLowerCase();
    final active = d.activeSubstances.first.trim().toLowerCase();
    if (active.isEmpty) return d.id.trim().toLowerCase();
    return 'group:$active';
  }

  bool _isFavoriteDrug(Drug d) {
    final idKey = d.id.trim().toLowerCase();
    final groupKey = _groupKeyForDrug(d);
    return _favorites.contains(idKey) || _favorites.contains(groupKey);
  }
}
