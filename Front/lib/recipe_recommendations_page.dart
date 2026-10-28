import 'package:flutter/material.dart';

const _forest = Color(0xFF173F32);
const _leaf = Color(0xFF2C7655);
const _canvas = Color(0xFFF5F7F0);

/// HU4 recipe suggestions view. The host feature supplies its authenticated API call.
class RecipeRecommendationsPage extends StatefulWidget {
  const RecipeRecommendationsPage({
    required this.loadRecommendations,
    super.key,
  });

  final Future<List<RecipeRecommendation>> Function() loadRecommendations;

  @override
  State<RecipeRecommendationsPage> createState() => _RecipeRecommendationsPageState();
}

class _RecipeRecommendationsPageState extends State<RecipeRecommendationsPage> {
  late Future<List<RecipeRecommendation>> _recommendations;

  @override
  void initState() {
    super.initState();
    _recommendations = widget.loadRecommendations();
  }

  void _reload() => setState(() => _recommendations = widget.loadRecommendations());

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(
          backgroundColor: _canvas,
          foregroundColor: _forest,
          title: const Text('Recetas para aprovechar', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: FutureBuilder<List<RecipeRecommendation>>(
                future: _recommendations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _leaf));
                  }
                  if (snapshot.hasError) {
                    return _MessageState(
                      icon: Icons.cloud_off_rounded,
                      title: 'No pudimos cargar las recetas',
                      detail: 'Revisa tu conexión e inténtalo de nuevo.',
                      action: FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                    );
                  }
                  final recipes = snapshot.data ?? const <RecipeRecommendation>[];
                  if (recipes.isEmpty) {
                    return const _MessageState(
                      icon: Icons.soup_kitchen_outlined,
                      title: 'Aún no hay coincidencias',
                      detail: 'Agrega alimentos a tu inventario y encontraremos recetas para aprovecharlos.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    color: _leaf,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: _forest, borderRadius: BorderRadius.circular(24)),
                          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(Icons.auto_awesome_rounded, color: Color(0xFFDDF27A)),
                            SizedBox(height: 10),
                            Text('Cocina con lo que ya tienes', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                            SizedBox(height: 5),
                            Text('Ordenamos las ideas según cuántos ingredientes de tu inventario puedes usar.',
                                style: TextStyle(color: Color(0xFFD7E3D8), height: 1.4)),
                          ]),
                        ),
                        const SizedBox(height: 18),
                        ...recipes.map((recipe) => _RecipeCard(recipe: recipe)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
}

class RecipeRecommendation {
  const RecipeRecommendation({
    required this.name,
    required this.description,
    required this.category,
    required this.minutes,
    required this.matches,
    required this.totalIngredients,
    required this.ingredients,
  });

  final String name;
  final String description;
  final String category;
  final int minutes;
  final int matches;
  final int totalIngredients;
  final List<RecipeIngredient> ingredients;

  factory RecipeRecommendation.fromJson(Map<String, dynamic> json) => RecipeRecommendation(
        name: json['nombre'] as String? ?? '',
        description: json['descripcion'] as String? ?? '',
        category: json['categoria'] as String? ?? 'Receta',
        minutes: (json['minutos'] as num?)?.toInt() ?? 0,
        matches: (json['coincidencias'] as num?)?.toInt() ?? 0,
        totalIngredients: (json['totalIngredientes'] as num?)?.toInt() ?? 0,
        ingredients: ((json['ingredientes'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RecipeIngredient.fromJson)
            .toList(growable: false),
      );
}

class RecipeIngredient {
  const RecipeIngredient({required this.name, required this.quantity, required this.unit, required this.available});

  final String name;
  final num quantity;
  final String unit;
  final bool available;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
        name: json['nombre'] as String? ?? '',
        quantity: json['cantidad'] as num? ?? 0,
        unit: json['unidad'] as String? ?? '',
        available: json['disponible'] as bool? ?? false,
      );
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final RecipeRecommendation recipe;

  @override
  Widget build(BuildContext context) {
    final percent = recipe.totalIngredients == 0 ? 0 : (recipe.matches * 100 / recipe.totalIngredients).round();
    final missing = recipe.ingredients.where((ingredient) => !ingredient.available).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFFE7ECE3))),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 46, height: 46,
                decoration: BoxDecoration(color: const Color(0xFFEAF2E5), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.restaurant_menu_rounded, color: _leaf)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(recipe.name, style: const TextStyle(color: _forest, fontSize: 16, fontWeight: FontWeight.w800)),
              Text('${recipe.category} · ${recipe.minutes} min', style: const TextStyle(color: Color(0xFF748078), fontSize: 12)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: const Color(0xFFDDF27A), borderRadius: BorderRadius.circular(20)),
                child: Text('$percent%', style: const TextStyle(color: _forest, fontWeight: FontWeight.w800))),
          ]),
          if (recipe.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(recipe.description, style: const TextStyle(color: Color(0xFF68756C), height: 1.4)),
          ],
          const SizedBox(height: 14),
          Wrap(spacing: 7, runSpacing: 7, children: recipe.ingredients.map((ingredient) {
            final color = ingredient.available ? _leaf : const Color(0xFF929B93);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: ingredient.available ? const Color(0xFFEDF4E9) : const Color(0xFFF1F2EF),
                  borderRadius: BorderRadius.circular(18)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(ingredient.available ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 14, color: color),
                const SizedBox(width: 5),
                Text('${ingredient.name} · ${ingredient.quantity} ${ingredient.unit}',
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            );
          }).toList()),
          const SizedBox(height: 12),
          Text(missing.isEmpty ? 'Tienes todo para prepararla.' : 'Te falta: ${missing.map((item) => item.name).join(', ')}',
              style: const TextStyle(color: Color(0xFF66736A), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.title, required this.detail, this.action});

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: _leaf, size: 42),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _forest, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF748078), height: 1.4)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}
