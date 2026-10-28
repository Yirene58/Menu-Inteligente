class CategoriaAlimento {
  const CategoriaAlimento({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  final int id;
  final String nombre;
  final String? descripcion;

  factory CategoriaAlimento.fromJson(Map<String, dynamic> json) {
    return CategoriaAlimento(
      id: (json['idCategoria'] as num).toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }
}
