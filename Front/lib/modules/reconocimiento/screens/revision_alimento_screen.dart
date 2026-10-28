import 'package:flutter/material.dart';

import '../../../models/categoria_alimento.dart';
import '../../../services/alimento_service.dart';

class RevisionAlimentosScreen extends StatefulWidget {
  const RevisionAlimentosScreen({
    required this.alimentosDetectados,
    super.key,
  });

  final List<dynamic> alimentosDetectados;

  @override
  State<RevisionAlimentosScreen> createState() =>
      _RevisionAlimentosScreenState();
}

class _RevisionAlimentosScreenState extends State<RevisionAlimentosScreen> {
  final AlimentoService _alimentoService = AlimentoService();
  late List<Map<String, dynamic>> _items;

  List<CategoriaAlimento> _categoriasUsuario = [];
  bool _loadingCategorias = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.alimentosDetectados
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final cats = await _alimentoService.listarCategorias();
      if (!mounted) return;

      setState(() {
        _categoriasUsuario = cats;
        _loadingCategorias = false;

        // Mapear cada elemento devuelto por Gemini a un idCategoria válido de la BD
        for (var item in _items) {
          final idRecibido = (item['idCategoria'] as num?)?.toInt();
          final existeId = cats.any((c) => c.id == idRecibido);

          if (existeId) {
            item['idCategoria'] = idRecibido;
          } else {
            final catNombre = (item['categoriaNombre'] ?? item['categoria'] ?? '')
                .toString()
                .toLowerCase();

            final coincidencia = cats.firstWhere(
              (c) =>
                  c.nombre.toLowerCase().contains(catNombre) ||
                  catNombre.contains(c.nombre.toLowerCase()),
              orElse: () => cats.isNotEmpty ? cats.first : CategoriaAlimento(id: 1, nombre: 'Otros'),
            );

            item['idCategoria'] = coincidencia.id;
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCategorias = false);
      }
    }
  }

  void _agregarNuevoAlimento() {
    setState(() {
      _items.add({
        'nombre': '',
        'cantidad': 1,
        'unidadMedida': 'unidad',
        'idCategoria': _categoriasUsuario.isNotEmpty ? _categoriasUsuario.first.id : null,
        'descripcion': 'Agregado manualmente',
      });
    });
  }

  void _eliminarItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _confirmarYGuardar() async {
    if (_items.isEmpty) return;

    setState(() => _saving = true);

    try {
      bool todoOk = true;

      for (final item in _items) {
        final nombre = item['nombre']?.toString().trim() ?? '';
        final idCategoria = (item['idCategoria'] as num?)?.toInt();
        final cantidad = (item['cantidad'] as num?)?.toDouble() ?? 1.0;
        final unidadMedida = item['unidadMedida']?.toString().trim().toLowerCase() ?? 'unidad';
        final descripcion = item['descripcion']?.toString().trim() ?? 'Escaneado por IA';

        if (nombre.isEmpty || idCategoria == null) {
          todoOk = false;
          continue;
        }

        try {
          await _alimentoService.crearAlimento(
            nombre: nombre,
            idCategoria: idCategoria,
            descripcion: descripcion,
            cantidad: cantidad,
            unidadMedida: unidadMedida,
          );
        } catch (_) {
          todoOk = false;
        }
      }

      if (!mounted) return;

      if (todoOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Alimentos guardados en el inventario exitosamente!'),
            backgroundColor: Color(0xFF075C4D),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocurrió un problema al guardar algunos alimentos.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _normalizarUnidad(dynamic unidad) {
    final u = unidad?.toString().trim().toLowerCase() ?? 'unidad';
    const permitidas = ['unidad', 'kg', 'g', 'litro', 'ml'];
    return permitidas.contains(u) ? u : 'unidad';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FBF8),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Revisar Alimentos',
          style: TextStyle(
            color: Color(0xFF093C36),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _loadingCategorias
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay alimentos en la lista. Presiona "Agregar otro".',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final currentCatId = (item['idCategoria'] as num?)?.toInt();

                              return Card(
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Color(0xFFDCE9E1)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: item['nombre']?.toString() ?? '',
                                              decoration: const InputDecoration(
                                                labelText: 'Nombre del alimento',
                                                isDense: true,
                                              ),
                                              onChanged: (val) {
                                                item['nombre'] = val;
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _eliminarItem(index),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: TextFormField(
                                              initialValue: item['cantidad']?.toString() ?? '1',
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(
                                                labelText: 'Cantidad',
                                                isDense: true,
                                              ),
                                              onChanged: (val) {
                                                item['cantidad'] = num.tryParse(val) ?? 1;
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 1,
                                            child: DropdownButtonFormField<String>(
                                              initialValue: _normalizarUnidad(item['unidadMedida']),
                                              decoration: const InputDecoration(
                                                labelText: 'Unidad',
                                                isDense: true,
                                              ),
                                              items: const [
                                                DropdownMenuItem(value: 'unidad', child: Text('unidad')),
                                                DropdownMenuItem(value: 'kg', child: Text('kg')),
                                                DropdownMenuItem(value: 'g', child: Text('g')),
                                                DropdownMenuItem(value: 'litro', child: Text('litro')),
                                                DropdownMenuItem(value: 'ml', child: Text('ml')),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  item['unidadMedida'] = val;
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: DropdownButtonFormField<int>(
                                              initialValue: _categoriasUsuario.any((c) => c.id == currentCatId)
                                                  ? currentCatId
                                                  : (_categoriasUsuario.isNotEmpty ? _categoriasUsuario.first.id : null),
                                              decoration: const InputDecoration(
                                                labelText: 'Categoría',
                                                isDense: true,
                                              ),
                                              items: _categoriasUsuario
                                                  .map(
                                                    (cat) => DropdownMenuItem<int>(
                                                      value: cat.id,
                                                      child: Text(cat.nombre),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() {
                                                    item['idCategoria'] = val;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // BARRA INFERIOR CON AMBOS BOTONES RESTAURADOS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _agregarNuevoAlimento,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF075C4D),
                              side: const BorderSide(color: Color(0xFF075C4D)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text(
                              'Agregar otro',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: (_saving || _items.isEmpty) ? null : _confirmarYGuardar,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF075C4D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                              _saving ? 'Guardando...' : 'Confirmar todo',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}