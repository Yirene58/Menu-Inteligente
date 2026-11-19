import 'package:flutter/material.dart';

import '../../models/categoria_alimento.dart';
import '../../services/alimento_service.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _service = AlimentoService();
  late Future<List<CategoriaAlimento>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _categoriesFuture = _service.listarCategorias();
  }

  Future<void> _editCategory([CategoriaAlimento? category]) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.nombre ?? '');
    final descriptionController = TextEditingController(
      text: category?.descripcion ?? '',
    );

    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(category == null ? 'Nueva categoría' : 'Editar categoría'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe un nombre.'
                    : null,
              ),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, {
                'nombre': nameController.text.trim(),
                'descripcion': descriptionController.text.trim(),
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    nameController.dispose();
    descriptionController.dispose();
    if (values == null) return;

    try {
      if (category == null) {
        await _service.crearCategoria(
          nombre: values['nombre']!,
          descripcion: values['descripcion'],
        );
      } else {
        await _service.actualizarCategoria(
          id: category.id,
          nombre: values['nombre']!,
          descripcion: values['descripcion'],
        );
      }
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    }
  }

  Future<void> _deleteCategory(CategoriaAlimento category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Quieres eliminar "${category.nombre}"? No podrás eliminarla mientras tenga alimentos asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.eliminarCategoria(category.id);
      if (!mounted) return;
      setState(_reload);
      _showMessage('Categoría eliminada.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBF8),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7FBF8),
      surfaceTintColor: Colors.transparent,
      title: const Text('Mis categorías'),
      actions: [
        IconButton(
          onPressed: () => setState(_reload),
          tooltip: 'Actualizar categorías',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _editCategory,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Crear categoría'),
    ),
    body: FutureBuilder<List<CategoriaAlimento>>(
      future: _categoriesFuture,
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
                  Text(
                    'No se pudieron cargar las categorías: ${snapshot.error}',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final categories = snapshot.data ?? const <CategoriaAlimento>[];
        if (categories.isEmpty) {
          return const Center(child: Text('Aún no tienes categorías.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              color: Colors.white,
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.category_outlined),
                ),
                title: Text(category.nombre),
                subtitle: category.descripcion?.isNotEmpty == true
                    ? Text(category.descripcion!)
                    : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') _editCategory(category);
                    if (action == 'delete') _deleteCategory(category);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
