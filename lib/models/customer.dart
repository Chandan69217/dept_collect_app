class Customer {
  final String id;
  final String name;
  final double amountDue;
  final DateTime dueDate;
  final int overdueDays;
  final String address;
  final String phone;
  final String priority; // 'HIGH', 'MEDIUM', 'LOW'
  final String avatarUrl;
  final double lat;
  final double lng;
  final String assignedAgentId;
  final String status; // 'PAID', 'OVERDUE', 'PENDING_VERIFICATION'
  final List<String> notes;
  final DateTime? scheduledVisit;
  final String assetModel;
  final String assetRegNo;
  final String engineNumber;
  final String chasisNumber;
  final String assetVariant;

  const Customer({
    required this.id,
    required this.name,
    required this.amountDue,
    required this.dueDate,
    required this.overdueDays,
    required this.address,
    required this.phone,
    required this.priority,
    required this.avatarUrl,
    required this.lat,
    required this.lng,
    required this.assignedAgentId,
    required this.status,
    this.notes = const [],
    this.scheduledVisit,
    this.assetModel = '',
    this.assetRegNo = '',
    this.engineNumber = '',
    this.chasisNumber = '',
    this.assetVariant = '',
  });

  Customer copyWith({
    String? id,
    String? name,
    double? amountDue,
    DateTime? dueDate,
    int? overdueDays,
    String? address,
    String? phone,
    String? priority,
    String? avatarUrl,
    double? lat,
    double? lng,
    String? assignedAgentId,
    String? status,
    List<String>? notes,
    DateTime? scheduledVisit,
    String? assetModel,
    String? assetRegNo,
    String? engineNumber,
    String? chasisNumber,
    String? assetVariant,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      amountDue: amountDue ?? this.amountDue,
      dueDate: dueDate ?? this.dueDate,
      overdueDays: overdueDays ?? this.overdueDays,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      priority: priority ?? this.priority,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      scheduledVisit: scheduledVisit ?? this.scheduledVisit,
      assetModel: assetModel ?? this.assetModel,
      assetRegNo: assetRegNo ?? this.assetRegNo,
      engineNumber: engineNumber ?? this.engineNumber,
      chasisNumber: chasisNumber ?? this.chasisNumber,
      assetVariant: assetVariant ?? this.assetVariant,
    );
  }
}
