class Alimento {
  const Alimento({
    required this.nombre,
    required this.cantidad,
    required this.unidadMedida,
  });

  final String nombre;
  final double cantidad;
  final String unidadMedida;

  factory Alimento.fromJson(Map<String, dynamic> json) => Alimento(
    nombre: json['nombre'] as String? ?? '',
    cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
    unidadMedida: json['unidadMedida'] as String? ?? '',
  );
}
