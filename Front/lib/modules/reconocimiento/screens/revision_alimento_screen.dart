import 'package:flutter/material.dart';

import '../../../models/alimento_revision.dart';
import '../../../models/categoria_alimento.dart';
import '../../../services/alimento_service.dart';

class RevisionAlimentosScreen extends StatefulWidget {
  const RevisionAlimentosScreen({required this.alimentosDetectados, super.key});

  final List<dynamic> alimentosDetectados;

  @override
  State<RevisionAlimentosScreen> createState() =>
      _RevisionAlimentosScreenState();
}

class _RevisionAlimentosScreenState extends State<RevisionAlimentosScreen> {
  static const _units = ['unidad', 'kg', 'g', 'litro', 'ml'];

  final _service = AlimentoService();
  late final List<_FoodDraft> _foods;
  List<CategoriaAlimento> _categories = [];
  String? _categoryError;
  bool _loadingCategories = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _foods = widget.alimentosDetectados
        .whereType<Map>()
        .map(
          (item) => _FoodDraft(
            AlimentoRevision.fromJson(Map<String, dynamic>.from(item)),
          ),
        )
        .toList();
    _loadCategories();
  }

  @override
  void dispose() {
    for (final food in _foods) {
      food.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoryError = null;
    });
    try {
      final categories = await _service.listarCategorias();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
        for (final food in _foods) {
          food.categoryId = _findCategory(food.categoryName)?.id;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _categoryError = error.toString();
        _loadingCategories = false;
      });
    }
  }

  static String _normalize(String value) {
    const accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    };
    final lower = value.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(accents[char] ?? char);
    }
    return buffer.toString();
  }

  /// Busca la categoría del usuario que corresponde a la detectada, sin
  /// importar mayúsculas ni tildes ("Proteinas" == "Proteínas"). Si no existe,
  /// usa "Otros" en lugar de asignar una categoría cualquiera.
  CategoriaAlimento? _findCategory(String name) {
    final normalized = _normalize(name);
    for (final category in _categories) {
      if (_normalize(category.nombre) == normalized) return category;
    }
    for (final category in _categories) {
      if (_normalize(category.nombre) == 'otros') return category;
    }
    return _categories.isEmpty ? null : _categories.first;
  }

  void _addFood() {
    setState(() {
      _foods.add(
        _FoodDraft(
          const AlimentoRevision(
            nombre: '',
            categoriaNombre: '',
            cantidad: 1,
            unidadMedida: 'unidad',
            descripcion: '',
          ),
        )..categoryId = _findCategory('Otros')?.id,
      );
    });
  }

  void _removeFood(int index) {
    setState(() {
      _foods.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    if (_foods.isEmpty || _saving) return;
    final invalid = _foods.indexWhere((food) => !food.isValid);
    if (invalid != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Revisa el alimento ${invalid + 1}: nombre, categoría y cantidad.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Un solo request transaccional: o se guardan todos o ninguno.
      await _service.crearAlimentosLote([
        for (final food in _foods)
          _service.payloadAlimento(
            nombre: food.name.text.trim(),
            idCategoria: food.categoryId!,
            descripcion: food.description,
            cantidad: food.quantity,
            unidadMedida: food.unit,
            fechaVencimiento: food.expiryDate,
          ),
      ]);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se guardaron los alimentos: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBF8),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7FBF8),
      surfaceTintColor: Colors.transparent,
      title: const Text('Revisar alimentos'),
    ),
    body: _loadingCategories
        ? const Center(child: CircularProgressIndicator())
        : _categoryError != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No se pudieron cargar las categorías: $_categoryError',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadCategories,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        : _categories.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Crea una categoría antes de guardar alimentos.'),
            ),
          )
        : Column(
            children: [
              Expanded(
                child: _foods.isEmpty
                    ? const Center(
                        child: Text('No hay alimentos para revisar.'),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text(
                            'Verifica la detección y ajusta cada dato antes de agregarlo al inventario.',
                          ),
                          const SizedBox(height: 12),
                          for (var index = 0; index < _foods.length; index++)
                            _foodCard(index),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _addFood,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar alimento'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving || _foods.isEmpty ? null : _save,
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Guardar inventario'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );

  Widget _foodCard(int index) {
    final food = _foods[index];
    final warningColor = Colors.orange.shade800;
    return Card(
      key: ObjectKey(food),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: food.uncertain
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: warningColor, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alimento ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (food.uncertain)
                  Tooltip(
                    message: 'La identificación es dudosa. Verifica el nombre.',
                    child: Chip(
                      avatar: Icon(
                        Icons.help_outline,
                        size: 18,
                        color: warningColor,
                      ),
                      label: const Text('Incierto'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                IconButton(
                  tooltip: 'Quitar alimento',
                  onPressed: _saving ? null : () => _removeFood(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextField(
              controller: food.name,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre',
                helperText: food.uncertain
                    ? 'Revisa este alimento antes de guardarlo.'
                    : null,
                helperStyle: TextStyle(color: warningColor),
              ),
              onChanged: (_) {
                if (food.uncertain) setState(() => food.uncertain = false);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: food.categoryId,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final category in _categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.nombre),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => food.categoryId = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: food.quantityController,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: food.unit,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: [
                      for (final unit in _units)
                        DropdownMenuItem(value: unit, child: Text(unit)),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => food.unit = value);
                            }
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _pickExpiry(food),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      food.expiryDate == null
                          ? 'Vencimiento (opcional)'
                          : 'Vence: ${_formatDate(food.expiryDate!)}',
                    ),
                  ),
                ),
                if (food.expiryDate != null)
                  IconButton(
                    tooltip: 'Quitar fecha',
                    onPressed: _saving
                        ? null
                        : () => setState(() => food.expiryDate = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiry(_FoodDraft food) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: food.expiryDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) setState(() => food.expiryDate = picked);
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _FoodDraft {
  _FoodDraft(AlimentoRevision food)
    : name = TextEditingController(text: food.nombre),
      quantityController = TextEditingController(
        text: food.cantidad.toString(),
      ),
      categoryName = food.categoriaNombre,
      unit =
          _RevisionAlimentosScreenState._units.contains(
            food.unidadMedida.toLowerCase(),
          )
          ? food.unidadMedida.toLowerCase()
          : 'unidad',
      description = food.descripcion,
      uncertain = food.incierto;

  final TextEditingController name;
  final TextEditingController quantityController;
  final String categoryName;
  final String description;
  int? categoryId;
  String unit;
  bool uncertain;
  DateTime? expiryDate;

  double get quantity =>
      double.tryParse(quantityController.text.trim().replaceAll(',', '.')) ??
      double.nan;

  bool get isValid =>
      name.text.trim().isNotEmpty &&
      categoryId != null &&
      quantity.isFinite &&
      quantity >= 0;

  void dispose() {
    name.dispose();
    quantityController.dispose();
  }
}
