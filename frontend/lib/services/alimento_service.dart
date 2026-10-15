import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/categoria_alimento.dart';
import 'storage_service.dart';

class AlimentoService {
  Future<List<CategoriaAlimento>> listarCategorias() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/alimentos/categorias'),
      headers: await _headers(),
    );
    _checkResponse(response, 'No fue posible cargar las categorías');

    final categories = jsonDecode(response.body) as List<dynamic>;
    return categories
        .map(
          (category) => CategoriaAlimento.fromJson(
            Map<String, dynamic>.from(category as Map),
          ),
        )
        .toList();
  }

  Future<void> crearAlimento({
    required String nombre,
    required int idCategoria,
    required String descripcion,
    required num cantidad,
    required String unidadMedida,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/alimentos'),
      headers: await _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'idCategoria': idCategoria,
        'descripcion': descripcion,
        'cantidad': cantidad,
        'unidadMedida': unidadMedida,
      }),
    );
    _checkResponse(response, 'No fue posible guardar el alimento');
  }

  Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const AlimentoApiException(
        'La sesión expiró. Inicia sesión de nuevo.',
      );
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _checkResponse(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message = fallbackMessage;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['mensaje'] as String? ?? fallbackMessage;
    } catch (_) {
      message = fallbackMessage;
    }
    throw AlimentoApiException(message);
  }
}

class AlimentoApiException implements Exception {
  const AlimentoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
