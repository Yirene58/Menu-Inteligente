import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ReconocimientoService {
  final String baseUrl = 'http://localhost:8080/api/reconocimiento/analizar';

  Future<Map<String, dynamic>> analizarImagen(XFile imagenFile) async {
    try {
      // 1. Leer bytes y procesar imagen
      Uint8List bytesOriginales = await imagenFile.readAsBytes();
      img.Image? imagenOriginal = img.decodeImage(bytesOriginales);
      
      if (imagenOriginal == null) {
        throw Exception('No se pudo procesar la imagen seleccionada.');
      }

      // Redimensionar a máximo 600px
      img.Image imagenProcesada = imagenOriginal;
      if (imagenOriginal.width > 600 || imagenOriginal.height > 600) {
        imagenProcesada = img.copyResize(
          imagenOriginal,
          width: imagenOriginal.width > imagenOriginal.height ? 600 : null,
          height: imagenOriginal.height >= imagenOriginal.width ? 600 : null,
        );
      }

      // Comprimir JPG al 70%
      List<int> bytesComprimidos = img.encodeJpg(imagenProcesada, quality: 70);
      String base64String = base64Encode(bytesComprimidos);

      // 2. Preparar el cliente
      var client = http.Client();
      if (kIsWeb) {
        final fetchClient = BrowserClient()..withCredentials = false;
        client = fetchClient;
      }

      // 3. Enviar la petición
      final response = await client.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'imagenBase64': base64String,
        }),
      );

      print('STATUS BACKEND: ${response.statusCode}');
      print('RESPONSE BACKEND: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error del backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en ReconocimientoService: $e');
      rethrow;
    }
  }
}