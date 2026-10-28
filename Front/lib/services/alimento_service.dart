import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/alimento.dart';
import '../models/categoria_alimento.dart';
import 'storage_service.dart';

class AlimentoService {
  Future<List<Alimento>> listarAlimentos() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/alimentos'),
      headers: await _headers(),
    );
    _checkResponse(response, 'No fue posible cargar los alimentos');

    final foods = jsonDecode(response.body) as List<dynamic>;
    return foods
        .map(
          (food) => Alimento.fromJson(Map<String, dynamic>.from(food as Map)),
        )
        .toList();
  }

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

  Future<void> crearCategoria({
    required String nombre,
    String? descripcion,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/alimentos/categorias'),
      headers: await _headers(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    _checkResponse(response, 'No fue posible crear la categoría');
  }

  Future<void> actualizarCategoria({
    required int id,
    required String nombre,
    String? descripcion,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/alimentos/categorias/$id'),
      headers: await _headers(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    _checkResponse(response, 'No fue posible actualizar la categoría');
  }

  Future<void> eliminarCategoria(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/alimentos/categorias/$id'),
      headers: await _headers(),
    );
    _checkResponse(response, 'No fue posible eliminar la categoría');
  }

  Future<void> crearAlimento({
    required String nombre,
    required int idCategoria,
    required String descripcion,
    required num cantidad,
    required String unidadMedida,
    DateTime? fechaVencimiento,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/alimentos'),
      headers: await _headers(),
      body: jsonEncode(
        _payload(
          nombre: nombre,
          idCategoria: idCategoria,
          descripcion: descripcion,
          cantidad: cantidad,
          unidadMedida: unidadMedida,
          fechaVencimiento: fechaVencimiento,
        ),
      ),
    );
    _checkResponse(response, 'No fue posible guardar el alimento');
  }

  Future<void> actualizarAlimento({
    required int id,
    required String nombre,
    required int idCategoria,
    required String descripcion,
    required num cantidad,
    required String unidadMedida,
    DateTime? fechaVencimiento,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/alimentos/$id'),
      headers: await _headers(),
      body: jsonEncode(
        _payload(
          nombre: nombre,
          idCategoria: idCategoria,
          descripcion: descripcion,
          cantidad: cantidad,
          unidadMedida: unidadMedida,
          fechaVencimiento: fechaVencimiento,
        ),
      ),
    );
    _checkResponse(response, 'No fue posible actualizar el alimento');
  }

  Future<void> eliminarAlimento(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/alimentos/$id'),
      headers: await _headers(),
    );
    _checkResponse(response, 'No fue posible eliminar el alimento');
  }

  Map<String, dynamic> _payload({
    required String nombre,
    required int idCategoria,
    required String descripcion,
    required num cantidad,
    required String unidadMedida,
    DateTime? fechaVencimiento,
  }) => {
    'nombre': nombre,
    'idCategoria': idCategoria,
    'descripcion': descripcion,
    'cantidad': cantidad,
    'unidadMedida': unidadMedida,
    'fechaVencimiento': fechaVencimiento == null
        ? null
        : '${fechaVencimiento.year.toString().padLeft(4, '0')}-'
              '${fechaVencimiento.month.toString().padLeft(2, '0')}-'
              '${fechaVencimiento.day.toString().padLeft(2, '0')}',
  };

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
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        message =
            decoded['mensaje'] as String? ??
            decoded['error'] as String? ??
            decoded['message'] as String? ??
            fallbackMessage;
      }
    } on FormatException {
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
