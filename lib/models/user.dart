class User {
  final String id;
  final String username;
  final String name;
  final String email;
  final bool isAdmin;
  final bool isBlocked;
  final DateTime? lastPaymentDate;
  final double totalEarnings;
  final int completedServices;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.isAdmin = false,
    this.isBlocked = false,
    this.lastPaymentDate,
    this.totalEarnings = 0,
    this.completedServices = 0,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.parse(map['lastPaymentDate'])
          : null,
      totalEarnings: (map['totalEarnings'] ?? 0.0).toDouble(),
      completedServices: map['completedServices'] ?? 0,
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
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'totalEarnings': totalEarnings,
      'completedServices': completedServices,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    bool? isAdmin,
    bool? isBlocked,
    DateTime? lastPaymentDate,
    double? totalEarnings,
    int? completedServices,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      isBlocked: isBlocked ?? this.isBlocked,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      completedServices: completedServices ?? this.completedServices,
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
