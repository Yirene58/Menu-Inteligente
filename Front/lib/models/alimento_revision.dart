class AlimentoRevision {
  const AlimentoRevision({
    required this.nombre,
    required this.categoriaNombre,
    required this.cantidad,
    required this.unidadMedida,
    required this.descripcion,
  });

  final String nombre;
  final String categoriaNombre;
  final double cantidad;
  final String unidadMedida;
  final String descripcion;

  factory AlimentoRevision.fromJson(Map<String, dynamic> json) {
    final quantity = json['cantidad'];
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
    );
  }
}
