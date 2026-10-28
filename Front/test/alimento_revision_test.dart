import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/alimento_revision.dart';

void main() {
  test('AlimentoRevision reads detected food fields', () {
    final food = AlimentoRevision.fromJson({
      'nombre': 'Manzana',
      'categoriaNombre': 'Frutas',
      'cantidad': 2,
      'unidadMedida': 'unidad',
      'descripcion': 'Fruta fresca',
    });

    expect(food.nombre, 'Manzana');
    expect(food.categoriaNombre, 'Frutas');
    expect(food.cantidad, 2);
    expect(food.unidadMedida, 'unidad');
  });

  test('AlimentoRevision accepts the legacy recognition response shape', () {
    final food = AlimentoRevision.fromJson({
      'objeto': 'Tomate',
      'categoria': 'Verduras',
    });

    expect(food.nombre, 'Tomate');
    expect(food.categoriaNombre, 'Verduras');
    expect(food.cantidad, 1);
    expect(food.unidadMedida, 'unidad');
  });
}
