import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../auth/auth_screen.dart';
import '../../modules/reconocimiento/screens/reconocimiento_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    }
  }

  // Función para capturar foto o seleccionar de galería
  Future<void> _abrirCamaraOGaleria(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: Color(0xFF075C4D)),
                title: const Text('Tomar foto con la cámara'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1200,
                    maxHeight: 1200,
                    imageQuality: 85,
                  );
                  if (photo != null && context.mounted) {
                    _procesarImagenCapturada(context, photo);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF075C4D)),
                title: const Text('Seleccionar de la galería'),
                onTap: () async {
                  Navigator.pop(modalContext);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1200,
                    maxHeight: 1200,
                    imageQuality: 85,
                  );
                  if (image != null && context.mounted) {
                    _procesarImagenCapturada(context, image);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _procesarImagenCapturada(BuildContext context, XFile imagen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReconocimientoScreen(imagen: imagen),
      ),
    );
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
              )
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              color: const Color(0xFF0C6655),
            )
          ],
        ),
        body: FutureBuilder<String?>(
          future: StorageService.getEmail(),
          builder: (context, snapshot) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Banner Saludo
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
                      style: TextStyle(
                        color: Color(0xFFE3F7EA),
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // TARJETA: Escanear objeto para IA
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _abrirCamaraOGaleria(context),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF075C4D).withOpacity(0.12),
                          child: const Icon(
                            Icons.camera_enhance_rounded,
                            color: Color(0xFF075C4D),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Escanear objeto',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Color(0xFF093C36),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Toma una foto para analizar su impacto',
                                style: TextStyle(
                                  color: Color(0xFF718880),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF0C6655),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),
              const Text(
                'Explora tu espacio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF093C36),
                ),
              ),
              const SizedBox(height: 14),

              // Opciones del Menú
              const Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _MenuCard(
                    icon: Icons.insights_rounded,
                    title: 'Impacto',
                    subtitle: 'Mide tus avances',
                    color: Color(0xFF4A9A70),
                  ),
                  _MenuCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Ideas verdes',
                    subtitle: 'Inspírate y crea',
                    color: Color(0xFFF2AA4C),
                  ),
                  _MenuCard(
                    icon: Icons.groups_rounded,
                    title: 'Comunidad',
                    subtitle: 'Conecta y colabora',
                    color: Color(0xFF4785A3),
                  ),
                  _MenuCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Laboratorio',
                    subtitle: 'Próximamente',
                    color: Color(0xFF8B70BA),
                  ),
                ],
              ),
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
          gradient: LinearGradient(
            colors: [Color(0xFFB5E85A), Color(0xFF33B988)],
          ),
        ),
        child: Icon(
          Icons.bolt_rounded,
          color: const Color(0xFF064236),
          size: small ? 20 : 38,
        ),
      );
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title, subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 180,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title estará disponible pronto'),
                behavior: SnackBarBehavior.floating,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF093C36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF718880),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}