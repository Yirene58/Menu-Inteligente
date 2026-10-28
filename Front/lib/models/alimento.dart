class Alimento {
  const Alimento({
    this.idAlimento,
    required this.nombre,
    required this.idCategoria,
    required this.cantidad,
    required this.unidadMedida,
    this.descripcion,
  });

  final int? idAlimento;
  final String nombre;
  final int idCategoria;
  final double cantidad;
  final String unidadMedida;
  final String? descripcion;

  factory Alimento.fromJson(Map<String, dynamic> json) => Alimento(
        idAlimento: (json['idAlimento'] as num?)?.toInt(),
        nombre: json['nombre'] as String? ?? '',
        idCategoria: json['categoria'] != null
            ? (json['categoria']['idCategoria'] as num).toInt()
            : (json['idCategoria'] as num? ?? 1).toInt(),
        cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
        unidadMedida: json['unidadMedida'] as String? ?? 'unidad',
        descripcion: json['descripcion'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre.trim(),
        'idCategoria': idCategoria,
        'cantidad': cantidad,
        'unidadMedida': unidadMedida.trim().toLowerCase(),
        if (descripcion != null && descripcion!.isNotEmpty)
          'descripcion': descripcion!.trim(),
      };
}