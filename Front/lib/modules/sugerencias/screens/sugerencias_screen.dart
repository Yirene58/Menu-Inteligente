import 'package:flutter/material.dart';

import '../services/sugerencias_service.dart';

class SugerenciasScreen extends StatefulWidget {
  const SugerenciasScreen({super.key});

  @override
  State<SugerenciasScreen> createState() => _SugerenciasScreenState();
}

class _SugerenciasScreenState extends State<SugerenciasScreen> {
  static const Map<String, String> _filterLabels = {
    'VEGANO': 'Vegano',
    'VEGETARIANO': 'Vegetariano',
    'SIN_GLUTEN': 'Sin gluten',
    'SIN_LACTEOS': 'Sin lácteos',
    'SIN_LACTOSA': 'Sin lactosa',
    'SIN_FRUTOS_SECOS': 'Sin frutos secos',
  };

  final SugerenciasService _service = SugerenciasService();
  late Future<Map<String, dynamic>> _suggestions;
  Set<String> _selectedFilters = {};
  bool _savingFilters = false;

  @override
  void initState() {
    super.initState();
    _suggestions = _loadInitial();
  }

  Future<Map<String, dynamic>> _loadInitial() async {
    final filters = await _service.cargarFiltros();
    if (mounted) {
      setState(() => _selectedFilters = filters.toSet());
    }
    return _service.generar();
  }

  void _reload() {
    setState(() => _suggestions = _loadInitial());
  }

  void _changeFilter(String filter, bool enabled) {
    final previous = Set<String>.from(_selectedFilters);
    final updated = Set<String>.from(previous);
    if (enabled) {
      updated.add(filter);
    } else {
      updated.remove(filter);
    }
    setState(() {
      _selectedFilters = updated;
      _savingFilters = true;
      _suggestions = _saveFiltersAndGenerate(updated, previous);
    });
  }

  Future<Map<String, dynamic>> _saveFiltersAndGenerate(
    Set<String> updated,
    Set<String> previous,
  ) async {
    try {
      await _service.guardarFiltros(updated.toList());
      return await _service.generar();
    } catch (_) {
      if (mounted) setState(() => _selectedFilters = previous);
      rethrow;
    } finally {
      if (mounted) setState(() => _savingFilters = false);
    }
  }

  List<Map<String, dynamic>> _items(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _filterLabel(Object? value) =>
      _filterLabels[value] ?? value?.toString() ?? '';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBF8),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7FBF8),
      surfaceTintColor: Colors.transparent,
      title: const Text('Sugerencias'),
      actions: [
        IconButton(
          onPressed: _savingFilters ? null : _reload,
          tooltip: 'Actualizar sugerencias',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _suggestions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _filterSection(context),
              const SizedBox(height: 16),
              Text(snapshot.error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          );
        }

        final result = snapshot.data ?? {};
        final storage = _items(result['almacenamiento']);
        final recipes = _items(result['recetas']);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _filterSection(context),
            if (storage.isEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Agrega alimentos a tu inventario para recibir recomendaciones.',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const SizedBox(height: 20),
              Text(
                'Almacenamiento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final item in storage)
                _SuggestionRow(
                  title: item['ingrediente'] as String? ?? 'Alimento',
                  detail: item['instruccion'] as String? ?? '',
                  footer: _expiryDetail(item),
                ),
              const SizedBox(height: 20),
              Text(
                'Recetas posibles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (recipes.isEmpty)
                Text(
                  _selectedFilters.isEmpty
                      ? 'No se generaron recetas para los ingredientes disponibles. Intenta actualizar.'
                      : 'No encontramos recetas que coincidan con los filtros seleccionados.',
                  textAlign: TextAlign.center,
                )
              else
                for (final recipe in recipes)
                  _SuggestionRow(
                    title: recipe['nombre'] as String? ?? 'Receta',
                    detail:
                        'Coincidencias: ${recipe['coincidencias'] ?? 0} - Faltantes: ${recipe['faltantes'] ?? 0}',
                    footer: [
                      '${recipe['minutos'] ?? 0} min - ${recipe['categoria'] ?? ''}',
                      if (_items(recipe['ingredientes']).isNotEmpty)
                        'Ingredientes: ${_items(recipe['ingredientes']).map((ingredient) => '${ingredient['nombre']} ${ingredient['cantidad']} ${ingredient['unidad']}').join(', ')}',
                      if (_items(recipe['ingredientesFaltantes']).isNotEmpty)
                        'Por comprar: ${_items(recipe['ingredientesFaltantes']).map((ingredient) => '${ingredient['nombre']} ${ingredient['cantidad']} ${ingredient['unidad']}').join(', ')}',
                      if (recipe['filtrosCompatibles'] is List &&
                          (recipe['filtrosCompatibles'] as List).isNotEmpty)
                        'Compatible: ${(recipe['filtrosCompatibles'] as List).map(_filterLabel).join(', ')}',
                    ].join('\n'),
                  ),
            ],
          ],
        );
      },
    ),
  );

  Widget _filterSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Filtros alimentarios',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 4),
      Text(
        'Con varios filtros activos se mostrarán recetas que cumplan al menos uno.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final filter in SugerenciasService.filtrosDisponibles)
            FilterChip(
              label: Text(_filterLabel(filter)),
              selected: _selectedFilters.contains(filter),
              onSelected: _savingFilters
                  ? null
                  : (selected) => _changeFilter(filter, selected),
            ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'La aptitud se estima con los ingredientes declarados; no se garantiza ausencia de trazas o contaminación cruzada.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  String _expiryDetail(Map<String, dynamic> item) {
    final condition = item['condicion'] as String? ?? '';
    final rawDate = item['fechaVencimiento'] as String?;
    if (rawDate == null) {
      return [
        condition,
        'Sin fecha de vencimiento; prioridad normal',
      ].where((text) => text.isNotEmpty).join(' · ');
    }
    final date = DateTime.tryParse(rawDate);
    if (date == null) return condition;
    final days = (item['diasParaVencer'] as num?)?.toInt();
    final dateText = MaterialLocalizations.of(context).formatMediumDate(date);
    final status = switch (days) {
      null => 'Vence $dateText',
      < 0 => 'Vencido hace ${-days} ${-days == 1 ? 'día' : 'días'} · $dateText',
      0 => 'Vence hoy · $dateText',
      1 => 'Vence mañana · $dateText',
      <= 3 => 'Vence en $days días · $dateText',
      _ => 'Vence $dateText',
    };
    return [condition, status].where((text) => text.isNotEmpty).join(' · ');
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.title,
    required this.detail,
    required this.footer,
  });

  final String title;
  final String detail;
  final String footer;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFDCE9E1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (detail.isNotEmpty) ...[const SizedBox(height: 5), Text(detail)],
        if (footer.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(footer, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}
