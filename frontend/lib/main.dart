import 'package:flutter/material.dart';

const _forest = Color(0xFF173F32);
const _leaf = Color(0xFF2C7655);
const _lime = Color(0xFFDDF27A);
const _canvas = Color(0xFFF5F7F0);
const _ink = Color(0xFF1D3028);

void main() => runApp(const GestorTecnoApp());

class GestorTecnoApp extends StatelessWidget {
  const GestorTecnoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'GestorTecno',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: _canvas,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _leaf,
            primary: _forest,
            secondary: _lime,
            surface: Colors.white,
            error: const Color(0xFFCB5A43),
          ),
          textTheme: ThemeData.light().textTheme.apply(
            bodyColor: _ink,
            displayColor: _forest,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE4EAE1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE4EAE1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _leaf, width: 1.5),
            ),
          ),
        ),
        home: const PantryPage(),
      );
}

class PantryItem {
  PantryItem(this.name, this.quantity, this.unit, this.expires);

  final String name;
  final double quantity;
  final String unit;
  final DateTime expires;

  int daysLeft(DateTime today) => DateUtils.dateOnly(expires)
      .difference(DateUtils.dateOnly(today))
      .inDays;
}

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
    lowerBound: 0.96,
    upperBound: 1.04,
  )..repeat(reverse: true);

  final List<PantryItem> _items = [
    PantryItem('Tomate', 3, 'unidades', DateTime.now().add(const Duration(days: 1))),
    PantryItem('Huevo', 4, 'unidades', DateTime.now().add(const Duration(days: 5))),
    PantryItem('Papa', 2, 'unidades', DateTime.now().add(const Duration(days: 12))),
  ];

  static const _storageTips = <String, String>{
    'tomate': 'Déjalo sin lavar en un lugar fresco y ventilado. Refrigéralo si está muy maduro o cortado.',
    'huevo': 'Guárdalo en su caja, en un estante interior del refrigerador.',
    'papa': 'Consérvala seca, en un lugar oscuro y ventilado; evita refrigerarla.',
    'leche': 'Mantenla entre 1 y 4 °C, bien cerrada y en un estante interior.',
    'cebolla': 'Guárdala seca y ventilada, separada de las papas.',
    'zanahoria': 'Guárdala sin lavar en una bolsa o recipiente dentro del cajón de verduras.',
    'aguacate': 'Déjalo madurar a temperatura ambiente; cuando madure, refrigéralo.',
  };

  static const _recipes = <({String title, List<String> ingredients, int minutes})>[
    (title: 'Tortilla de papa', ingredients: ['huevo', 'papa', 'cebolla'], minutes: 30),
    (title: 'Ensalada de tomate y aguacate', ingredients: ['tomate', 'aguacate', 'cebolla'], minutes: 15),
    (title: 'Arroz con verduras', ingredients: ['arroz', 'zanahoria', 'cebolla', 'tomate'], minutes: 35),
    (title: 'Crema de zanahoria', ingredients: ['zanahoria', 'papa', 'leche', 'cebolla'], minutes: 30),
  ];

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    if (name.isEmpty || quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un ingrediente y una cantidad válida.')),
      );
      return;
    }
    setState(() {
      _items.add(PantryItem(
        name,
        quantity,
        'unidades',
        DateTime.now().add(const Duration(days: 7)),
      ));
      _nameController.clear();
      _quantityController.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final sortedItems = [..._items]
      ..sort((a, b) => a.daysLeft(today).compareTo(b.daysLeft(today)));
    final available = _items.map((item) => item.name.toLowerCase()).toSet();
    final recipes = _recipes
        .map((recipe) => (
              recipe: recipe,
              matches: recipe.ingredients.where(available.contains).length,
            ))
        .where((entry) => entry.matches > 0)
        .toList()
      ..sort((a, b) => b.matches.compareTo(a.matches));
    final urgentCount = _items.where((item) => item.daysLeft(today) <= 2).length;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1060),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 48),
              children: [
                _topBar(context),
                const SizedBox(height: 20),
                _hero(context, urgentCount),
                const SizedBox(height: 28),
                _sectionHeading(
                  context,
                  eyebrow: 'TU INVENTARIO',
                  title: 'Lo que tienes en casa',
                  subtitle: 'Cuídalo bien y úsalo a tiempo.',
                  icon: Icons.kitchen_rounded,
                  count: '${_items.length}',
                ),
                const SizedBox(height: 14),
                _addIngredientForm(context),
                const SizedBox(height: 12),
                if (sortedItems.isEmpty)
                  _emptyState(context)
                else
                  ...sortedItems.indexed.map((entry) => _ingredientCard(
                        context,
                        entry.$2,
                        today,
                        entry.$1,
                      )),
                const SizedBox(height: 30),
                _sectionHeading(
                  context,
                  eyebrow: 'IDEAS PARA HOY',
                  title: '¿Qué cocinamos?',
                  subtitle: 'Recetas que aprovechan lo que ya tienes.',
                  icon: Icons.restaurant_menu_rounded,
                  count: '${recipes.length}',
                ),
                const SizedBox(height: 14),
                if (recipes.isEmpty)
                  _emptyState(context, recipes: true)
                else
                  ...recipes.indexed.map((entry) => _recipeCard(
                        context,
                        entry.$2.recipe,
                        available,
                        entry.$2.matches,
                        entry.$1,
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) => FadeTransition(
        opacity: CurvedAnimation(parent: _intro, curve: const Interval(0, .8)),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _forest,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.eco_rounded, color: _lime, size: 24),
            ),
            const SizedBox(width: 11),
            Text(
              'gestortecno',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                    color: _forest,
                  ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFE7EDE3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.spa_rounded, color: _leaf, size: 17),
                  SizedBox(width: 7),
                  Text('Menos desperdicio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _hero(BuildContext context, int urgentCount) => AnimatedBuilder(
        animation: _intro,
        builder: (context, child) => Opacity(
          opacity: _intro.value,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - _intro.value)),
            child: child,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [_forest, Color(0xFF245D43), _leaf],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _forest.withValues(alpha: .18),
                    blurRadius: 28,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -60,
                    top: -105,
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: .09), width: 34),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 58,
                    bottom: -120,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _lime.withValues(alpha: .07),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(compact ? 23 : 34),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _heroCopy(context),
                              const SizedBox(height: 20),
                              _heroStats(urgentCount),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _heroCopy(context)),
                              const SizedBox(width: 26),
                              _heroStats(urgentCount),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _heroCopy(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: const Text(
              'DESPENSA INTELIGENTE',
              style: TextStyle(color: _lime, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Come rico.\nDesperdicia menos.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ideas frescas para cuidar tus alimentos y tu bolsillo.',
            style: TextStyle(color: Colors.white.withValues(alpha: .76), height: 1.4),
          ),
        ],
      );

  Widget _heroStats(int urgentCount) => AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Transform.scale(scale: _pulse.value, child: child),
        child: Container(
          width: 174,
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: _lime,
            borderRadius: BorderRadius.circular(23),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notifications_active_rounded, color: _forest, size: 25),
              const SizedBox(height: 13),
              Text('$urgentCount', style: const TextStyle(color: _forest, fontSize: 38, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(height: 5),
              Text(
                urgentCount == 1 ? 'ingrediente\npor usar pronto' : 'ingredientes\npor usar pronto',
                style: const TextStyle(color: _forest, fontSize: 12, fontWeight: FontWeight.w600, height: 1.35),
              ),
            ],
          ),
        ),
      );

  Widget _sectionHeading(
    BuildContext context, {
    required String eyebrow,
    required String title,
    required String subtitle,
    required IconData icon,
    required String count,
  }) => Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(color: const Color(0xFFE5EEDC), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: _forest, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow, style: const TextStyle(color: _leaf, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.4)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF748078))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFE8EDDF), borderRadius: BorderRadius.circular(30)),
            child: Text(count, style: const TextStyle(color: _forest, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      );

  Widget _addIngredientForm(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF1E6),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE1E9DC)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final nameField = TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: '¿Qué alimento guardaste?',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onSubmitted: (_) => _addItem(),
            );
            final quantityField = TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cantidad'),
              onSubmitted: (_) => _addItem(),
            );
            final addButton = FilledButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar'),
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 17),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nameField,
                  const SizedBox(height: 10),
                  Row(children: [Expanded(child: quantityField), const SizedBox(width: 10), addButton]),
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 5, child: nameField),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: quantityField),
                const SizedBox(width: 10),
                addButton,
              ],
            );
          },
        ),
      );

  Widget _ingredientCard(BuildContext context, PantryItem item, DateTime today, int index) {
    final days = item.daysLeft(today);
    final name = item.name.toLowerCase();
    final tip = _storageTips[name] ??
        'Sigue las indicaciones de la etiqueta. Consérvalo cerrado y revisa su estado antes de consumirlo.';
    final urgency = days < 0
        ? 'Vencido'
        : days == 0
            ? 'Vence hoy'
            : days == 1
                ? 'Vence mañana'
                : 'Vence en $days días';
    final urgent = days <= 2;
    final accent = urgent ? const Color(0xFFB9573E) : _leaf;

    return _staggered(
      'ingredient-${item.name}',
      index,
      Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: const BorderSide(color: Color(0xFFE9EDE5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: urgent ? const Color(0xFFFFE9E1) : const Color(0xFFE8F0E4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_foodIcon(name), color: accent, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink))),
                        Text('${_quantity(item.quantity)} ${item.unit}', style: const TextStyle(fontSize: 12, color: Color(0xFF78847A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: urgent ? const Color(0xFFFFF0EA) : const Color(0xFFEDF4E9), borderRadius: BorderRadius.circular(30)),
                      child: Text(urgency, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, color: _leaf.withValues(alpha: .8), size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(tip, style: const TextStyle(color: Color(0xFF66736A), fontSize: 12, height: 1.4))),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar ingrediente',
                onPressed: () => setState(() => _items.remove(item)),
                icon: const Icon(Icons.close_rounded, size: 19),
                style: IconButton.styleFrom(foregroundColor: const Color(0xFF9AA49B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recipeCard(
    BuildContext context,
    ({String title, List<String> ingredients, int minutes}) recipe,
    Set<String> available,
    int matches,
    int index,
  ) {
    final missing = recipe.ingredients.where((ingredient) => !available.contains(ingredient)).toList();
    return _staggered(
      'recipe-${recipe.title}',
      index,
      Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: const BorderSide(color: Color(0xFFE9EDE5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(color: const Color(0xFFFFF2D8), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.restaurant_rounded, color: Color(0xFF99722A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(recipe.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink))),
                  const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF829087)),
                  const SizedBox(width: 5),
                  Text('${recipe.minutes} min', style: const TextStyle(color: Color(0xFF6F7D73), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: recipe.ingredients.map((ingredient) {
                  final hasIt = available.contains(ingredient);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasIt ? const Color(0xFFEAF2E5) : const Color(0xFFF2F3EF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(hasIt ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 13, color: hasIt ? _leaf : const Color(0xFF9AA39A)),
                        const SizedBox(width: 5),
                        Text(ingredient, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hasIt ? _forest : const Color(0xFF737D74))),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(missing.isEmpty ? Icons.celebration_rounded : Icons.shopping_basket_outlined, size: 17, color: missing.isEmpty ? _leaf : const Color(0xFF8B7440)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      missing.isEmpty ? '¡Ya tienes todo para prepararla!' : 'Te falta: ${missing.join(', ')}',
                      style: TextStyle(fontSize: 12, color: missing.isEmpty ? _forest : const Color(0xFF776A4A), fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('$matches/${recipe.ingredients.length}', style: const TextStyle(color: _leaf, fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staggered(Object key, int index, Widget child) => TweenAnimationBuilder<double>(
        key: ValueKey(key),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + index * 75),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
        ),
        child: child,
      );

  Widget _emptyState(BuildContext context, {bool recipes = false}) => Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21), border: Border.all(color: const Color(0xFFE9EDE5))),
        child: Column(
          children: [
            Icon(recipes ? Icons.menu_book_rounded : Icons.inventory_2_outlined, size: 32, color: _leaf),
            const SizedBox(height: 9),
            Text(recipes ? 'Agrega alimentos para descubrir recetas.' : 'Tu despensa está vacía. ¡Empecemos!', style: const TextStyle(color: Color(0xFF718076))),
          ],
        ),
      );

  IconData _foodIcon(String name) {
    if (name.contains('tomate') || name.contains('manzana') || name.contains('aguacate')) return Icons.nutrition_rounded;
    if (name.contains('huevo') || name.contains('leche') || name.contains('queso')) return Icons.egg_alt_rounded;
    return Icons.eco_rounded;
  }

  String _quantity(double quantity) => quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1);
}
