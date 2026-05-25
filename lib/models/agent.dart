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
    );
  }
}
