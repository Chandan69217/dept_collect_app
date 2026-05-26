class Agent {
  final String id;
  final String name;
  final String avatarUrl;
  final String zone;
  final double assignedTarget;
  final double collectedAmount;
  final int casesCount;
  final int pendingVisitsCount;
  final bool isAdmin;
  final bool isOnline;
  final String email;
  final String phone;
  final String address;

  const Agent({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.zone,
    required this.assignedTarget,
    required this.collectedAmount,
    required this.casesCount,
    required this.pendingVisitsCount,
    this.isAdmin = false,
    this.isOnline = true,
    this.email = '',
    this.phone = '',
    this.address = '',
  });

  Agent copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? zone,
    double? assignedTarget,
    double? collectedAmount,
    int? casesCount,
    int? pendingVisitsCount,
    bool? isAdmin,
    bool? isOnline,
    String? email,
    String? phone,
    String? address,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      zone: zone ?? this.zone,
      assignedTarget: assignedTarget ?? this.assignedTarget,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      casesCount: casesCount ?? this.casesCount,
      pendingVisitsCount: pendingVisitsCount ?? this.pendingVisitsCount,
      isAdmin: isAdmin ?? this.isAdmin,
      isOnline: isOnline ?? this.isOnline,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
