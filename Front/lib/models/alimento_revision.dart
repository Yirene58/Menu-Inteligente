class AlimentoRevision {
  String nombre;
  int idCategoria;
  double cantidad;
  String unidadMedida;
  String descripcion;

  AlimentoRevision({
    required this.nombre,
    required this.idCategoria,
    required this.cantidad,
    required this.unidadMedida,
    this.descripcion = 'Escaneado por IA',
  });

  factory AlimentoRevision.fromJson(Map<String, dynamic> json) {
    return AlimentoRevision(
      nombre: json['nombre']?.toString() ?? '',
      idCategoria: int.tryParse(json['idCategoria']?.toString() ?? '1') ?? 1,
      cantidad: double.tryParse(json['cantidad']?.toString() ?? '1.0') ?? 1.0,
      unidadMedida: json['unidadMedida']?.toString() ?? 'unidad',
      descripcion: json['descripcion']?.toString() ?? 'Escaneado por IA',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'idCategoria': idCategoria,
      'cantidad': cantidad,
      'unidadMedida': unidadMedida,
      'descripcion': descripcion,
    };
  }
}