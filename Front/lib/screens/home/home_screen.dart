import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../../modules/reconocimiento/screens/reconocimiento_screen.dart';
import '../../modules/sugerencias/screens/sugerencias_screen.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../auth/auth_screen.dart';
import 'add_alimento_screen.dart';
import 'inventory_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _seleccionarImagen(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galeria'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null || !context.mounted) return;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ReconocimientoScreen(image: image),
        ),
      );
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alimentos agregados al inventario.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir la imagen.')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBF8),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7FBF8),
      surfaceTintColor: Colors.transparent,
      title: const Row(
        children: [
          _Mark(small: true),
          SizedBox(width: 10),
          Text(
            'NaturaGrid',
            style: TextStyle(
              color: Color(0xFF093C36),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_rounded),
          color: const Color(0xFF0C6655),
        ),
      ],
    ),
    body: FutureBuilder<String?>(
      future: StorageService.getEmail(),
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF075C4D), Color(0xFF16826A)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Mark(),
                const SizedBox(height: 22),
                Text(
                  'Hola, ${snapshot.data?.split('@').first ?? 'explorador'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 29,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu centro para crear impacto positivo empieza aquí.',
                  style: TextStyle(color: Color(0xFFE3F7EA), fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              textStyle: const TextStyle(fontSize: 16),
              iconSize: 22,
            ),
            onPressed: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddAlimentoScreen()),
              );
              if (saved == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alimento guardado correctamente.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Añadir Alimento Manualmente'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              textStyle: const TextStyle(fontSize: 16),
              iconSize: 22,
            ),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const InventoryScreen()),
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Ver mi inventario'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              textStyle: const TextStyle(fontSize: 16),
              iconSize: 22,
            ),
            onPressed: () => _seleccionarImagen(context),
            icon: const Icon(Icons.center_focus_strong_outlined),
            label: const Text('Reconocer alimento'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              textStyle: const TextStyle(fontSize: 16),
              iconSize: 22,
            ),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const SugerenciasScreen(),
              ),
            ),
            icon: const Icon(Icons.lightbulb_outline_rounded),
            label: const Text('Sugerencias para mi inventario'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

class _Mark extends StatelessWidget {
  const _Mark({this.small = false});
  final bool small;
  @override
  Widget build(BuildContext context) => Container(
    width: small ? 34 : 64,
    height: small ? 34 : 64,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [Color(0xFFB5E85A), Color(0xFF33B988)]),
    ),
    child: Icon(
      Icons.bolt_rounded,
      color: const Color(0xFF064236),
      size: small ? 20 : 38,
    ),
  );
}
