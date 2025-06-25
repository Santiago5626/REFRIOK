class User {
  final String id;
  final String username;
  final String name;
  final String email;
  final bool isAdmin;
  final bool isBlocked;
  final DateTime? blockedAt;
  final String? blockReason;
  final DateTime? lastPaymentDate;
  final double totalEarnings;
  final int completedServices;
  final String? sedeId;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.isAdmin = false,
    this.isBlocked = false,
    this.blockedAt,
    this.blockReason,
    this.lastPaymentDate,
    this.totalEarnings = 0,
    this.completedServices = 0,
    this.sedeId,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      blockedAt: map['blockedAt'] != null
          ? DateTime.parse(map['blockedAt'])
          : null,
      blockReason: map['blockReason'],
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.parse(map['lastPaymentDate'])
          : null,
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      completedServices: map['completedServices'] ?? 0,
      sedeId: map['sedeId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'isBlocked': isBlocked,
      'blockedAt': blockedAt?.toIso8601String(),
      'blockReason': blockReason,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'totalEarnings': totalEarnings,
      'completedServices': completedServices,
      'sedeId': sedeId,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    bool? isAdmin,
    bool? isBlocked,
    DateTime? blockedAt,
    String? blockReason,
    DateTime? lastPaymentDate,
    double? totalEarnings,
    int? completedServices,
    String? sedeId,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedAt: blockedAt ?? this.blockedAt,
      blockReason: blockReason ?? this.blockReason,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      completedServices: completedServices ?? this.completedServices,
      sedeId: sedeId ?? this.sedeId,
    );
  }

  bool shouldBeBlocked() {
    if (isAdmin) return false;
    
    if (lastPaymentDate == null) {
      return true;
    }

    final now = DateTime.now();
    final deadline = DateTime(
      now.year,
      now.month,
      now.day,
      22, // 10 PM
    );

    return now.isAfter(deadline) &&
        lastPaymentDate!.isBefore(DateTime(now.year, now.month, now.day));
  }
}
