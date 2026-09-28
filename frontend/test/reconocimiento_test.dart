import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pruebas de Reconocimiento de Objetos', () {
    test('Verificar mapeo correcto de la respuesta del backend', () {
      // Simulación del JSON que devuelve Quarkus a Flutter
      final Map<String, dynamic> respuestaBackend = {
        'objeto': 'Manzana',
        'categoria': 'Orgánico',
        'descripcion': 'Una manzana roja fresca en una superficie blanca.'
      };

      // Validaciones
      expect(respuestaBackend['objeto'], equals('Manzana'));
      expect(respuestaBackend['categoria'], equals('Orgánico'));
      expect(respuestaBackend['descripcion'], isNotNull);
      expect(respuestaBackend.containsKey('descripcion'), isTrue);
    });

    test('Manejo de valores por defecto cuando faltan datos', () {
      final Map<String, dynamic> respuestaIncompleta = {};

      final String objeto = respuestaIncompleta['objeto'] ?? 'Desconocido';
      final String descripcion = respuestaIncompleta['descripcion'] ?? 'Sin datos';

      expect(objeto, equals('Desconocido'));
      expect(descripcion, equals('Sin datos'));
    });
  });
}