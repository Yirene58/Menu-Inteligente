import 'package:flutter/material.dart';

import '../../models/alimento.dart';
import '../../models/alimento_form_validator.dart';
import '../../models/categoria_alimento.dart';
import '../../services/alimento_service.dart';

class AddAlimentoScreen extends StatefulWidget {
  const AddAlimentoScreen({super.key, this.alimento});

  final Alimento? alimento;

  @override
  State<AddAlimentoScreen> createState() => _AddAlimentoScreenState();
}

class _AddAlimentoScreenState extends State<AddAlimentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _service = AlimentoService();

  late Future<List<CategoriaAlimento>> _categoriesFuture;
  int? _selectedCategoryId;
  String? _selectedUnit;
  DateTime? _expiryDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final alimento = widget.alimento;
    if (alimento != null) {
      _nameController.text = alimento.nombre;
      _descriptionController.text = alimento.descripcion;
      _quantityController.text = alimento.cantidad.toString();
      _selectedCategoryId = alimento.idCategoria;
      _selectedUnit = alimento.unidadMedida;
      _expiryDate = alimento.fechaVencimiento;
    }
    _categoriesFuture = _service.listarCategorias();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _retryCategories() async {
    setState(() {
      _categoriesFuture = _service.listarCategorias();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría para continuar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final quantity = num.parse(
      _quantityController.text.trim().replaceAll(',', '.'),
    );
    setState(() => _saving = true);
    try {
      final alimento = widget.alimento;
      if (alimento?.id == null) {
        await _service.crearAlimento(
          nombre: _nameController.text.trim(),
          idCategoria: _selectedCategoryId!,
          descripcion: _descriptionController.text.trim(),
          cantidad: quantity,
          unidadMedida: _selectedUnit!,
          fechaVencimiento: _expiryDate,
        );
      } else {
        await _service.actualizarAlimento(
          id: alimento!.id!,
          nombre: _nameController.text.trim(),
          idCategoria: _selectedCategoryId!,
          descripcion: _descriptionController.text.trim(),
          cantidad: quantity,
          unidadMedida: _selectedUnit!,
          fechaVencimiento: _expiryDate,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 30),
      helpText: 'Selecciona la fecha de vencimiento',
    );
    if (picked != null && mounted) {
      setState(() => _expiryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = MaterialLocalizations.of(context)
        .formatMediumDate(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FBF8),
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.alimento == null ? 'Añadir alimento' : 'Editar alimento',
          style: const TextStyle(
            color: Color(0xFF093C36),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    widget.alimento == null
                        ? 'Registra un alimento'
                        : 'Actualiza tu alimento',
                    style: const TextStyle(
                      color: Color(0xFF093C36),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Completa los datos y agrega el vencimiento si lo conoces.',
                    style: TextStyle(color: Color(0xFF718880)),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) =>
                        AlimentoFormValidator.requiredValue(value, 'El nombre'),
                  ),
                  const SizedBox(height: 16),
                  _categoryField(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    validator: (value) => AlimentoFormValidator.requiredValue(
                      value,
                      'La descripción',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            prefixIcon: Icon(Icons.scale_outlined),
                          ),
                          validator: AlimentoFormValidator.validateQuantity,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _unitField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de registro',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(today),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _selectExpiryDate,
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(
                      _expiryDate == null
                          ? 'Añadir fecha de vencimiento (opcional)'
                          : 'Vence el ${MaterialLocalizations.of(context).formatMediumDate(_expiryDate!)}',
                    ),
                  ),
                  if (_expiryDate != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => _expiryDate = null),
                        child: const Text('Quitar fecha'),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving
                          ? 'Guardando...'
                          : widget.alimento == null
                          ? 'Guardar alimento'
                          : 'Guardar cambios',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryField() {
    return FutureBuilder<List<CategoriaAlimento>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const InputDecorator(
            decoration: InputDecoration(
              labelText: 'Categoría',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Categoría',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('No se pudieron cargar las categorías'),
                ),
                IconButton(
                  tooltip: 'Reintentar carga de categorías',
                  onPressed: _retryCategories,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          );
        }

        final categories = snapshot.data!;
        return DropdownButtonFormField<int>(
          initialValue:
              categories.any((category) => category.id == _selectedCategoryId)
              ? _selectedCategoryId
              : null,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: categories
              .map(
                (category) => DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.nombre),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedCategoryId = value),
          validator: (value) => AlimentoFormValidator.requiredValue(
            value?.toString(),
            'La categoría',
          ),
        );
      },
    );
  }

  Widget _unitField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedUnit,
      decoration: const InputDecoration(
        labelText: 'Unidad',
        prefixIcon: Icon(Icons.straighten_rounded),
      ),
      items: AlimentoFormValidator.unidadesPermitidas
          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
          .toList(),
      onChanged: (value) => setState(() => _selectedUnit = value),
      validator: AlimentoFormValidator.validateUnit,
    );
  }
}
