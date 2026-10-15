import 'dart:convert';

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
        'La sesion expiro. Inicia sesion de nuevo.',
      );
    }

    final originalBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(originalBytes);
    if (decodedImage == null) {
      throw const ReconocimientoException(
        'No se pudo procesar la imagen seleccionada.',
      );
    }

    final resizedImage = decodedImage.width > 600 || decodedImage.height > 600
        ? img.copyResize(
            decodedImage,
            width: decodedImage.width >= decodedImage.height ? 600 : null,
            height: decodedImage.height > decodedImage.width ? 600 : null,
          )
        : decodedImage;
    final encodedImage = base64Encode(img.encodeJpg(resizedImage, quality: 70));

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
        .timeout(const Duration(seconds: 45));

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
          responseBody?['error'] as String? ??
          responseBody?['message'] as String? ??
          'No fue posible analizar la imagen (${response.statusCode}).';
      throw ReconocimientoException(message);
    }

    if (responseBody == null) {
      throw const ReconocimientoException(
        'El backend devolvio una respuesta invalida.',
      );
    }
    return responseBody;
  }
}

class ReconocimientoException implements Exception {
  const ReconocimientoException(this.message);

  final String message;

  @override
  String toString() => message;
}
