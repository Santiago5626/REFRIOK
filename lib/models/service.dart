enum ServiceStatus {
  pending,    // Servicio disponible para tomar
  assigned,   // Servicio aceptado por técnico
  onWay,      // Técnico en camino
  inProgress, // Técnico en el lugar
  completed,  // Servicio completado
  cancelled,  // Servicio cancelado
  paid        // Servicio pagado al admin
}

enum ServiceType {
  revision,   // Solo revisión (30.000)
  complete    // Servicio completo
}

class Service {
  final String id;
  final String title;
  final String description;
  final String location;
  final String clientName;
  final String clientPhone;
  final DateTime createdAt;
  final DateTime scheduledFor;
  final double basePrice;
  final String? assignedTechnicianId;
  final ServiceStatus status;
  final ServiceType? serviceType;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? additionalDetails;
  final bool isPaid;
  final DateTime? paidAt;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.clientName,
    required this.clientPhone,
    required this.createdAt,
    required this.scheduledFor,
    required this.basePrice,
    this.assignedTechnicianId,
    this.status = ServiceStatus.pending,
    this.serviceType,
    this.arrivedAt,
    this.completedAt,
    this.additionalDetails,
    this.isPaid = false,
    this.paidAt,
  });

  // Verifica si el técnico debe ser bloqueado automáticamente
  bool shouldBlockTechnician() {
    if (!isPaid && status == ServiceStatus.completed) {
      final now = DateTime.now();
      final deadline = DateTime(
        completedAt!.year,
        completedAt!.month,
        completedAt!.day,
        22, // 10 PM
      );
      return now.isAfter(deadline);
    }
    return false;
  }

  // Porcentajes de comisión
  static const double adminCommissionRate = 0.30; // 30% para admin
  static const double technicianCommissionRate = 0.70; // 70% para técnico

  double get finalPrice {
    // Para revisiones y servicios completos, usar el precio base de la sede
    return basePrice;
  }

  double get adminCommission {
    return finalPrice * adminCommissionRate;
  }

  double get technicianCommission {
    return finalPrice * technicianCommissionRate;
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      scheduledFor: DateTime.parse(map['scheduledFor'] ?? DateTime.now().toIso8601String()),
      basePrice: (map['basePrice'] ?? 0.0).toDouble(),
      assignedTechnicianId: map['assignedTechnicianId'],
      status: ServiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ServiceStatus.pending,
      ),
      serviceType: map['serviceType'] != null 
          ? ServiceType.values.firstWhere(
              (e) => e.toString().split('.').last == map['serviceType'],
              orElse: () => ServiceType.complete,
            )
          : null,
      arrivedAt: map['arrivedAt'] != null ? DateTime.parse(map['arrivedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      additionalDetails: map['additionalDetails'],
      isPaid: map['isPaid'] ?? false,
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor.toIso8601String(),
      'basePrice': basePrice,
      'assignedTechnicianId': assignedTechnicianId,
      'status': status.toString().split('.').last,
      'serviceType': serviceType?.toString().split('.').last,
      'arrivedAt': arrivedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'additionalDetails': additionalDetails,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  Service copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? clientName,
    String? clientPhone,
    DateTime? createdAt,
    DateTime? scheduledFor,
    double? basePrice,
    String? assignedTechnicianId,
    ServiceStatus? status,
    ServiceType? serviceType,
    DateTime? arrivedAt,
    DateTime? completedAt,
    Map<String, dynamic>? additionalDetails,
    bool? isPaid,
    DateTime? paidAt,
  }) {
    return Service(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      basePrice: basePrice ?? this.basePrice,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      completedAt: completedAt ?? this.completedAt,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  bool get isOverdue {
    final now = DateTime.now();
    final deadline = DateTime(
      scheduledFor.year,
      scheduledFor.month,
      scheduledFor.day,
      22, // 10 PM
    );
    return now.isAfter(deadline) && status != ServiceStatus.completed;
  }
}
