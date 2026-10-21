import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/alimento.dart';

void main() {
  group('Alimento', () {
    test('parses inventory details and optional expiry date', () {
      final alimento = Alimento.fromJson({
        'idAlimento': 7,
        'nombre': 'Tomate',
        'cantidad': 2,
        'unidadMedida': 'unidad',
        'descripcion': 'Maduro',
        'categoria': {'idCategoria': 3, 'nombre': 'Verduras'},
        'fechaVencimiento': '2026-10-25',
      });

      expect(alimento.id, 7);
      expect(alimento.idCategoria, 3);
      expect(alimento.categoriaNombre, 'Verduras');
      expect(alimento.fechaVencimientoIso, '2026-10-25');
    });

    test('calculates days to expiry without time-of-day effects', () {
      final alimento = Alimento(
        id: 1,
        nombre: 'Leche',
        cantidad: 1,
        unidadMedida: 'litro',
        fechaVencimiento: DateTime(2026, 10, 24),
      );

      expect(alimento.diasParaVencer(DateTime(2026, 10, 21, 23)), 3);
    });

    test('allows inventory items without an expiry date', () {
      final alimento = Alimento(
        id: 1,
        nombre: 'Arroz',
        cantidad: 1,
        unidadMedida: 'kg',
      );

      expect(alimento.fechaVencimientoIso, isNull);
      expect(alimento.diasParaVencer(), isNull);
    });
  });
}
