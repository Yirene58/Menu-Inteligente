class AlimentoFormValidator {
  static const List<String> unidadesPermitidas = [
    'kg',
    'g',
    'unidad',
    'litro',
    'ml'
  ];

  static String? requiredValue(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio.';
    }
    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La cantidad es obligatoria.';
    }
    final numValue = num.tryParse(value.replaceAll(',', '.'));
    if (numValue == null || numValue < 0) {
      return 'Ingresa una cantidad válida mayor o igual a 0.';
    }
    return null;
  }

  static String? validateUnit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Selecciona una unidad de medida.';
    }
    if (!unidadesPermitidas.contains(value.trim().toLowerCase())) {
      return 'Unidad no válida.';
    }
    return null;
  }
}