import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/reconocimiento_service.dart';

class ReconocimientoScreen extends StatefulWidget {
  const ReconocimientoScreen({required this.image, super.key});

  final XFile image;

  @override
  State<ReconocimientoScreen> createState() => _ReconocimientoScreenState();
}

class _ReconocimientoScreenState extends State<ReconocimientoScreen> {
  late final Future<Uint8List> _imageBytes;
  Map<String, dynamic>? _result;
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
      setState(() => _result = result);
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
          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDCE9E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _result!['objeto'] as String? ?? 'Sin identificar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(_result!['categoria'] as String? ?? 'General'),
                  const SizedBox(height: 12),
                  Text(_result!['descripcion'] as String? ?? ''),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
