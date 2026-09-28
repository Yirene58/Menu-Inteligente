import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/reconocimiento_service.dart';

class ReconocimientoScreen extends StatefulWidget {
  final XFile imagen;

  const ReconocimientoScreen({super.key, required this.imagen});

  @override
  State<ReconocimientoScreen> createState() => _ReconocimientoScreenState();
}

class _ReconocimientoScreenState extends State<ReconocimientoScreen> {
  bool _analizando = false;
  Map<String, dynamic>? _resultado;
  String? _error;

  Future<void> _analizarImagen() async {
    setState(() {
      _analizando = true;
      _error = null;
    });

    try {
      final respuesta = await ReconocimientoService().analizarImagen(widget.imagen);
      setState(() {
        _resultado = respuesta;
      });
    } catch (e) {
      setState(() {
        _error = 'Ocurrió un error al procesar la imagen con el backend.';
      });
    } finally {
      setState(() {
        _analizando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FBF8),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Análisis de Objeto',
          style: TextStyle(color: Color(0xFF093C36), fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0C6655)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: Colors.black12,
                    child: kIsWeb
                        ? Image.network(widget.imagen.path, fit: BoxFit.cover, width: double.infinity)
                        : Image.file(File(widget.imagen.path), fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              if (_resultado != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F7EA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF33B988)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objeto: ${_resultado!['objeto'] ?? 'Desconocido'}',
                        style: const TextStyle(
                          color: Color(0xFF093C36),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Categoría: ${_resultado!['categoria'] ?? 'N/A'}',
                        style: const TextStyle(color: Color(0xFF0C6655), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Descripción: ${_resultado!['descripcion'] ?? 'Sin datos'}',
                        style: const TextStyle(color: Color(0xFF093C36), fontSize: 13),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075C4D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _analizando ? null : _analizarImagen,
                  icon: _analizando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  label: Text(
                    _analizando ? 'Analizando...' : 'Analizar objeto',
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}