class Sede {
  final String id;
  final String nombre;
  final double valorBaseRevision;
  final DateTime createdAt;
  final bool activa;

  Sede({
    required this.id,
    required this.nombre,
    required this.valorBaseRevision,
    required this.createdAt,
    this.activa = true,
  });

  factory Sede.fromMap(Map<String, dynamic> map) {
    return Sede(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      valorBaseRevision: (map['valorBaseRevision'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      activa: map['activa'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'valorBaseRevision': valorBaseRevision,
      'createdAt': createdAt.toIso8601String(),
      'activa': activa,
    };
  }

  Sede copyWith({
    String? id,
    String? nombre,
    double? valorBaseRevision,
    DateTime? createdAt,
    bool? activa,
  }) {
    return Sede(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      valorBaseRevision: valorBaseRevision ?? this.valorBaseRevision,
      createdAt: createdAt ?? this.createdAt,
      activa: activa ?? this.activa,
    );
  }
}
