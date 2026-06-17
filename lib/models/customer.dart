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
  final bool showLoanId;

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
    this.showLoanId = true,
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
    bool? showLoanId,
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
      showLoanId: showLoanId ?? this.showLoanId,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      overdueDays: json['overdueDays'] as int? ?? 0,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      priority: json['priority'] as String? ?? 'MEDIUM',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      assignedAgentId: json['assignedAgentId'] as String? ?? '',
      status: json['status'] as String? ?? 'OVERDUE',
      notes: (json['notes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      scheduledVisit: json['scheduledVisit'] != null
          ? DateTime.tryParse(json['scheduledVisit'] as String)
          : null,
      assetModel: json['assetModel'] as String? ?? '',
      assetRegNo: json['assetRegNo'] as String? ?? '',
      engineNumber: json['engineNumber'] as String? ?? '',
      chasisNumber: json['chasisNumber'] as String? ?? '',
      assetVariant: json['assetVariant'] as String? ?? '',
      showLoanId: json['showLoanId'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amountDue': amountDue,
      'dueDate': dueDate.toIso8601String(),
      'overdueDays': overdueDays,
      'address': address,
      'phone': phone,
      'priority': priority,
      'avatarUrl': avatarUrl,
      'lat': lat,
      'lng': lng,
      'assignedAgentId': assignedAgentId,
      'status': status,
      'notes': notes,
      'scheduledVisit': scheduledVisit?.toIso8601String(),
      'assetModel': assetModel,
      'assetRegNo': assetRegNo,
      'engineNumber': engineNumber,
      'chasisNumber': chasisNumber,
      'assetVariant': assetVariant,
      'showLoanId': showLoanId,
    };
  }
}
