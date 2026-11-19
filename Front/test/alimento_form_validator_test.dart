import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/alimento_form_validator.dart';

void main() {
  group('AlimentoFormValidator', () {
    test('requires a name', () {
      expect(_isValid(name: ' '), isFalse);
    });

    test('requires a category', () {
      expect(_isValid(categoryId: null), isFalse);
    });

    test('requires a description', () {
      expect(_isValid(description: ''), isFalse);
    });

    test('requires a valid quantity', () {
      expect(_isValid(quantity: ''), isFalse);
      expect(AlimentoFormValidator.validateQuantity('-1'), isNotNull);
      expect(AlimentoFormValidator.validateQuantity('1,5'), isNull);
    });

    test('requires a supported unit', () {
      expect(_isValid(unit: ''), isFalse);
      expect(AlimentoFormValidator.validateUnit('paquete'), isNotNull);
    });

    test('accepts a complete alimento', () {
      expect(_isValid(), isTrue);
    });
  });
}

bool _isValid({
  String? name = 'Manzana',
  String? categoryId = '1',
  String? description = 'Manzanas frescas',
  String? quantity = '2',
  String? unit = 'kg',
}) {
  return AlimentoFormValidator.isValid(
    name: name,
    categoryId: categoryId,
    description: description,
    quantity: quantity,
    unit: unit,
  );
}
