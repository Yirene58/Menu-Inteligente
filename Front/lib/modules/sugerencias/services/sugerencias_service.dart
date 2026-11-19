import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../../../services/alimento_service.dart';
import '../../../services/storage_service.dart';

class SugerenciasService {
  static const List<String> filtrosDisponibles = [
    'VEGANO',
    'VEGETARIANO',
    'SIN_GLUTEN',
    'SIN_LACTEOS',
    'SIN_LACTOSA',
    'SIN_FRUTOS_SECOS',
  ];

  Future<List<String>> cargarFiltros() async {
    final response = await http
        .get(Uri.parse(ApiConfig.dietaryFiltersUrl), headers: await _headers())
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AlimentoApiException(
        'No fue posible cargar tus filtros alimentarios.',
      );
    }
    final body = jsonDecode(response.body);
    if (body is! Map || body['filtros'] is! List) {
      throw const AlimentoApiException(
        'La respuesta de filtros alimentarios es invalida.',
      );
    }
    return (body['filtros'] as List).whereType<String>().toList();
  }

  Future<void> guardarFiltros(List<String> filters) async {
    final response = await http
        .put(
          Uri.parse(ApiConfig.dietaryFiltersUrl),
          headers: await _headers(),
          body: jsonEncode({'filtros': filters}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AlimentoApiException(
        'No fue posible guardar tus filtros alimentarios.',
      );
    }
  }

  Future<Map<String, dynamic>> generar() async {
    final foods = await AlimentoService().listarAlimentos();
    if (foods.isEmpty) {
      return {'almacenamiento': <dynamic>[], 'recetas': <dynamic>[]};
    }

    final response = await http
        .post(
          Uri.parse(ApiConfig.suggestionsUrl),
          headers: await _headers(),
          body: jsonEncode({
            'fechaActual': DateTime.now().toIso8601String().split('T').first,
            'ingredientes': foods
                .map(
                  (food) => {
                    'nombre': food.nombre,
                    'cantidad': food.cantidad,
                    'unidad': food.unidadMedida,
                    'fechaVencimiento': food.fechaVencimientoIso,
                  },
                )
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AlimentoApiException(
        'No fue posible generar las sugerencias.',
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map) {
      throw const AlimentoApiException(
        'El backend devolvio una respuesta invalida.',
      );
    }
    return Map<String, dynamic>.from(body);
  }

  Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const AlimentoApiException(
        'La sesion expiro. Inicia sesion de nuevo.',
      );
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
