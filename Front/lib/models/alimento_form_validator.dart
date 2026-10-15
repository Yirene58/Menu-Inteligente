class AlimentoFormValidator {
  static const unidadesPermitidas = ['kg', 'g', 'unidad', 'litro', 'ml'];

  static String? requiredValue(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  static String? validateQuantity(String? value) {
    final requiredError = requiredValue(value, 'La cantidad');
    if (requiredError != null) return requiredError;

    final quantity = num.tryParse(value!.trim().replaceAll(',', '.'));
    if (quantity == null || !quantity.isFinite || quantity < 0) {
      return 'Ingresa una cantidad válida';
    }
    return null;
  }

  static String? validateUnit(String? value) {
    final requiredError = requiredValue(value, 'La unidad de medida');
    if (requiredError != null) return requiredError;
    if (!unidadesPermitidas.contains(value!.trim().toLowerCase())) {
      return 'Selecciona una unidad válida';
    }
    return null;
  }

  static bool isValid({
    required String? name,
    required String? categoryId,
    required String? description,
    required String? quantity,
    required String? unit,
  }) {
    return requiredValue(name, 'El nombre') == null &&
        requiredValue(categoryId, 'La categoría') == null &&
        requiredValue(description, 'La descripción') == null &&
        validateQuantity(quantity) == null &&
        validateUnit(unit) == null;
  }
}
