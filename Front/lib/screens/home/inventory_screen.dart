import 'package:flutter/material.dart';

import '../../models/alimento.dart';
import '../../services/alimento_service.dart';
import 'add_alimento_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _service = AlimentoService();
  final _searchController = TextEditingController();
  late Future<List<Alimento>> _foodsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _foodsFuture = _service.listarAlimentos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _foodsFuture = _service.listarAlimentos());
  }

  Future<void> _openForm([Alimento? alimento]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddAlimentoScreen(alimento: alimento)),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _delete(Alimento alimento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Quieres eliminar ${alimento.nombre} del inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || alimento.id == null) return;

    try {
      await _service.eliminarAlimento(alimento.id!);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Producto eliminado.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBF8),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7FBF8),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Mi inventario',
        style: TextStyle(color: Color(0xFF093C36), fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          onPressed: _reload,
          tooltip: 'Actualizar inventario',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _openForm,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Agregar'),
    ),
    body: FutureBuilder<List<Alimento>>(
      future: _foodsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar el inventario',
            message: snapshot.error.toString(),
            actionLabel: 'Reintentar',
            onAction: _reload,
          );
        }

        final foods = snapshot.data ?? const <Alimento>[];
        if (foods.isEmpty) {
          return _MessageState(
            icon: Icons.inventory_2_outlined,
            title: 'Tu inventario está vacío',
            message: 'Agrega productos para tenerlos organizados y recibir sugerencias.',
            actionLabel: 'Agregar primer producto',
            onAction: _openForm,
          );
        }
        final filtered =
            foods
                .where((food) => food.nombre.toLowerCase().contains(_query))
                .toList()
              ..sort(
                (first, second) => (first.diasParaVencer() ?? 0x7fffffff)
                    .compareTo(second.diasParaVencer() ?? 0x7fffffff),
              );
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(
                '${foods.length} ${foods.length == 1 ? 'producto' : 'productos'}',
                style: const TextStyle(
                  color: Color(0xFF718880),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar producto',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDCE9E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDCE9E1)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'No hay productos que coincidan con la búsqueda.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final food in filtered) ...[
                _FoodCard(
                  alimento: food,
                  onEdit: food.id == null ? null : () => _openForm(food),
                  onDelete: food.id == null ? null : () => _delete(food),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    ),
  );
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.alimento,
    required this.onEdit,
    required this.onDelete,
  });

  final Alimento alimento;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final days = alimento.diasParaVencer();
    final Color accent;
    final IconData expiryIcon;
    final String expiryText;
    if (days == null) {
      accent = const Color(0xFF718880);
      expiryIcon = Icons.event_busy_outlined;
      expiryText = 'Sin fecha de vencimiento';
    } else if (days < 0) {
      accent = const Color(0xFFB3261E);
      expiryIcon = Icons.warning_amber_rounded;
      expiryText = 'Vencido hace ${-days} ${-days == 1 ? 'día' : 'días'}';
    } else if (days <= 3) {
      accent = const Color(0xFFB45F06);
      expiryIcon = Icons.schedule_rounded;
      expiryText = days == 0
          ? 'Vence hoy'
          : 'Vence en $days ${days == 1 ? 'día' : 'días'}';
    } else {
      accent = const Color(0xFF26734D);
      expiryIcon = Icons.event_available_outlined;
      expiryText =
          'Vence ${MaterialLocalizations.of(context).formatMediumDate(alimento.fechaVencimiento!)}';
    }

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDCE9E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.eco_outlined, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alimento.nombre,
                    style: const TextStyle(
                      color: Color(0xFF093C36),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${alimento.cantidad} ${alimento.unidadMedida}'
                    '${alimento.categoriaNombre.isEmpty ? '' : ' · ${alimento.categoriaNombre}'}',
                    style: const TextStyle(color: Color(0xFF718880)),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(expiryIcon, size: 16, color: accent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          expiryText,
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Acciones de ${alimento.nombre}',
              onSelected: (action) {
                if (action == 'edit') onEdit?.call();
                if (action == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Eliminar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: const Color(0xFF16826A)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF093C36),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    ),
  );
}
