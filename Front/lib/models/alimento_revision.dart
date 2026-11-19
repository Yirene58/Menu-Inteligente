class AlimentoRevision {
  const AlimentoRevision({
    required this.nombre,
    required this.categoriaNombre,
    required this.cantidad,
    required this.unidadMedida,
    required this.descripcion,
    this.confianza = 1,
    this.incierto = false,
  });

  final String nombre;
  final String categoriaNombre;
  final double cantidad;
  final String unidadMedida;
  final String descripcion;

  /// Seguridad del modelo en la identificación (0 a 1).
  final double confianza;

  /// true cuando la identificación es dudosa y el usuario debe corregirla.
  final bool incierto;

  factory AlimentoRevision.fromJson(Map<String, dynamic> json) {
    final quantity = json['cantidad'];
    final rawConfidence = json['confianza'];
    final confidence = rawConfidence is num
        ? rawConfidence.clamp(0, 1).toDouble()
        : double.tryParse(rawConfidence?.toString() ?? '') ?? 1.0;
    return AlimentoRevision(
      nombre: (json['nombre'] ?? json['objeto'] ?? '').toString().trim(),
      categoriaNombre: (json['categoriaNombre'] ?? json['categoria'] ?? 'Otros')
          .toString()
          .trim(),
      cantidad: quantity is num
          ? quantity.toDouble()
          : double.tryParse(quantity?.toString() ?? '') ?? 1,
      unidadMedida: (json['unidadMedida'] ?? 'unidad').toString().trim(),
      descripcion: (json['descripcion'] ?? '').toString().trim(),
      confianza: confidence,
      incierto: json['incierto'] == true || confidence < 0.6,
    );
  }
}
