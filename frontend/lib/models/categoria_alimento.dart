class CategoriaAlimento {
  const CategoriaAlimento({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory CategoriaAlimento.fromJson(Map<String, dynamic> json) {
    return CategoriaAlimento(
      id: (json['idCategoria'] as num).toInt(),
      nombre: json['nombre'] as String,
    );
  }
}
