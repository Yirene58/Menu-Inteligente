import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../../../services/alimento_service.dart';
import '../../../services/storage_service.dart';

class SugerenciasService {
  Future<Map<String, dynamic>> generar() async {
    final foods = await AlimentoService().listarAlimentos();
    if (foods.isEmpty) {
      return {'almacenamiento': <dynamic>[], 'recetas': <dynamic>[]};
    }

    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const AlimentoApiException(
        'La sesion expiro. Inicia sesion de nuevo.',
      );
    }

    final response = await http
        .post(
          Uri.parse(ApiConfig.suggestionsUrl),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'fechaActual': DateTime.now().toIso8601String().split('T').first,
            'ingredientes': foods
                .map(
                  (food) => {
                    'nombre': food.nombre,
                    'cantidad': food.cantidad,
                    'unidad': food.unidadMedida,
                    'fechaVencimiento': null,
                  },
                )
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 20));

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
}
