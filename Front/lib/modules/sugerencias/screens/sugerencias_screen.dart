import 'package:flutter/material.dart';

import '../services/sugerencias_service.dart';

class SugerenciasScreen extends StatefulWidget {
  const SugerenciasScreen({super.key});

  @override
  State<SugerenciasScreen> createState() => _SugerenciasScreenState();
}

class _SugerenciasScreenState extends State<SugerenciasScreen> {
  late Future<Map<String, dynamic>> _suggestions;

  @override
  void initState() {
    super.initState();
    _suggestions = SugerenciasService().generar();
  }

  void _reload() {
    setState(() => _suggestions = SugerenciasService().generar());
  }

  List<Map<String, dynamic>> _items(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBF8),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7FBF8),
      surfaceTintColor: Colors.transparent,
      title: const Text('Sugerencias'),
      actions: [
        IconButton(
          onPressed: _reload,
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final result = snapshot.data ?? {};
        final storage = _items(result['almacenamiento']);
        final recipes = _items(result['recetas']);
        if (storage.isEmpty && recipes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Agrega alimentos a tu inventario para recibir recomendaciones.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (storage.isNotEmpty) ...[
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
            ],
            if (recipes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Recetas posibles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final recipe in recipes)
                _SuggestionRow(
                  title: recipe['nombre'] as String? ?? 'Receta',
                  detail:
                      'Coincidencias: ${recipe['coincidencias'] ?? 0} - Faltantes: ${recipe['faltantes'] ?? 0}',
                  footer:
                      '${recipe['minutos'] ?? 0} min - ${recipe['categoria'] ?? ''}',
                ),
            ],
          ],
        );
      },
    ),
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
