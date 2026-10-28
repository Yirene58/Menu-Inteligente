class AlimentoFormValidator {
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    return null;
  }

  static String? validateCategory(dynamic categoryId) {
    if (categoryId == null) {
      return 'La categoría es obligatoria';
    }
    return null;
  }

  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'La descripción es obligatoria';
    }
    return null;
  }

  static String? validateQuantity(String? quantity) {
    if (quantity == null || quantity.trim().isEmpty) {
      return 'La cantidad es obligatoria';
    }
    final normalized = quantity.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa una cantidad válida mayor a 0';
    }
    return null;
  }

  static String? validateUnit(String? unit) {
    if (unit == null || unit.trim().isEmpty) {
      return 'La unidad es obligatoria';
    }
    const permitidas = ['unidad', 'kg', 'g', 'litro', 'ml'];
    if (!permitidas.contains(unit.trim().toLowerCase())) {
      return 'Unidad no soportada';
    }
    return null;
  }

  // 🔴 ESTE ES EL MÉTODO QUE LE FALTA A TU CLASE:
  static bool isValid({
    String? name,
    dynamic categoryId,
    String? description,
    String? quantity,
    String? unit,
  }) {
    return validateName(name) == null &&
        validateCategory(categoryId) == null &&
        validateDescription(description) == null &&
        validateQuantity(quantity) == null &&
        validateUnit(unit) == null;
  }
}