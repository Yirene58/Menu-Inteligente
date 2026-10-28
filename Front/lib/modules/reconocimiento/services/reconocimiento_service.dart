import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../config/api_config.dart';
import '../../../services/storage_service.dart';

class ReconocimientoService {
  Future<Map<String, dynamic>> analizarImagen(XFile imageFile) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const ReconocimientoException(
        'La sesión expiró. Inicia sesión de nuevo.',
      );
    }

    final originalBytes = await imageFile.readAsBytes();
    final String encodedImage = await compute(_procesarYComprimirImagen, originalBytes);

    if (encodedImage.isEmpty) {
      throw const ReconocimientoException(
        'No se pudo procesar o decodificar la imagen seleccionada.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.recognitionUrl),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'imagenBase64': encodedImage,
              'nombreArchivo': imageFile.name,
            }),
          )
          .timeout(const Duration(seconds: 90));

      Map<String, dynamic>? responseBody;
      try {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map) {
          responseBody = Map<String, dynamic>.from(decodedBody);
        }
      } on FormatException {
        responseBody = null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message =
            responseBody?['mensaje'] as String? ??
            responseBody?['error'] as String? ??
            responseBody?['message'] as String? ??
            'No fue posible analizar la imagen (${response.statusCode}).';
        throw ReconocimientoException(message);
      }

      if (responseBody == null) {
        throw const ReconocimientoException(
          'El backend devolvió una respuesta inválida.',
        );
      }

      return responseBody;
    } on TimeoutException {
      throw const ReconocimientoException(
        'La IA tardó demasiado en responder. Por favor, intenta de nuevo.',
      );
    } on http.ClientException {
      throw const ReconocimientoException(
        'Error de conexión con el servidor. Verifica que el backend esté activo.',
      );
    } catch (e) {
      if (e is ReconocimientoException) rethrow;
      throw ReconocimientoException('Error al comunicar con el servidor: $e');
    }
  }
}

String _procesarYComprimirImagen(Uint8List originalBytes) {
  try {
    final decodedImage = img.decodeImage(originalBytes);
    if (decodedImage == null) return '';

    final resizedImage = decodedImage.width > 600 || decodedImage.height > 600
        ? img.copyResize(
            decodedImage,
            width: decodedImage.width >= decodedImage.height ? 600 : null,
            height: decodedImage.height > decodedImage.width ? 600 : null,
          )
        : decodedImage;

    return base64Encode(img.encodeJpg(resizedImage, quality: 70));
  } catch (_) {
    return base64Encode(originalBytes);
  }
}

class ReconocimientoException implements Exception {
  const ReconocimientoException(this.message);

  final String message;

  @override
  String toString() => message;
}