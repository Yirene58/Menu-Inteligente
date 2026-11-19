class Alimento {
  const Alimento({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.unidadMedida,
    this.descripcion = '',
    this.idCategoria,
    this.categoriaNombre = '',
    this.fechaVencimiento,
  });

  final int? id;
  final String nombre;
  final double cantidad;
  final String unidadMedida;
  final String descripcion;
  final int? idCategoria;
  final String categoriaNombre;
  final DateTime? fechaVencimiento;

  factory Alimento.fromJson(Map<String, dynamic> json) {
    final category = json['categoria'];
    final categoryJson = category is Map
        ? Map<String, dynamic>.from(category)
        : <String, dynamic>{};
    final expiry = json['fechaVencimiento'] as String?;
    return Alimento(
      id: (json['idAlimento'] as num?)?.toInt(),
      nombre: json['nombre'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
      unidadMedida: json['unidadMedida'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      idCategoria: (categoryJson['idCategoria'] as num?)?.toInt(),
      categoriaNombre: categoryJson['nombre'] as String? ?? '',
      fechaVencimiento: expiry == null ? null : DateTime.tryParse(expiry),
    );
  }

  String? get fechaVencimientoIso => fechaVencimiento == null
      ? null
      : '${fechaVencimiento!.year.toString().padLeft(4, '0')}-'
            '${fechaVencimiento!.month.toString().padLeft(2, '0')}-'
            '${fechaVencimiento!.day.toString().padLeft(2, '0')}';

  int? diasParaVencer([DateTime? hoy]) {
    if (fechaVencimiento == null) return null;
    final today = hoy ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final expiryDate = DateTime(
      fechaVencimiento!.year,
      fechaVencimiento!.month,
      fechaVencimiento!.day,
    );
    return expiryDate.difference(todayDate).inDays;
  }
}
