import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/reconocimiento_service.dart';
import 'revision_alimento_screen.dart';

class ReconocimientoScreen extends StatefulWidget {
  const ReconocimientoScreen({required this.image, super.key});

  final XFile image;

  @override
  State<ReconocimientoScreen> createState() => _ReconocimientoScreenState();
}

class _ReconocimientoScreenState extends State<ReconocimientoScreen> {
  late final Future<Uint8List> _imageBytes;
  String? _error;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.image.readAsBytes();
  }

  Future<void> _analyze() async {
    setState(() {
      _analyzing = true;
      _error = null;
    });

    try {
      final result = await ReconocimientoService().analizarImagen(widget.image);
      if (!mounted) return;
      final detectedFoods = result['alimentos'];
      if (detectedFoods is! List || detectedFoods.isEmpty) {
        throw const ReconocimientoException(
          'No se reconocieron alimentos en la imagen.',
        );
      }

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) =>
              RevisionAlimentosScreen(alimentosDetectados: detectedFoods),
        ),
      );
      if (saved == true && mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBF8),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7FBF8),
      surfaceTintColor: Colors.transparent,
      title: const Text('Reconocer alimento'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 280,
              child: FutureBuilder<Uint8List>(
                future: _imageBytes,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _analyzing ? null : _analyze,
            icon: _analyzing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(_analyzing ? 'Analizando...' : 'Analizar imagen'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
  );
}
