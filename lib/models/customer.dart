import 'assignment.dart';

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
  final String assignedAgentName;
  final String status; // 'Assigned', 'Pending', 'Completed', 'Rejected', 'Closed'
  final List<String> notes;
  final DateTime? scheduledVisit;
  final String assetModel;
  final String assetRegNo;
  final String engineNumber;
  final String chasisNumber;
  final String assetVariant;
  final bool showLoanId;
  final String loanId;
  final String assignedBy;
  final int? assignmentId;
  final Assignment? assignment;

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
    required this.assignedAgentName,
    required this.status,
    this.notes = const [],
    this.scheduledVisit,
    this.assetModel = '',
    this.assetRegNo = '',
    this.engineNumber = '',
    this.chasisNumber = '',
    this.assetVariant = '',
    this.loanId = '',
    this.showLoanId = true,
    this.assignedBy = '',
    this.assignmentId,
    this.assignment,
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
    String? assignedAgentName,
    String? status,
    List<String>? notes,
    DateTime? scheduledVisit,
    String? assetModel,
    String? assetRegNo,
    String? engineNumber,
    String? chasisNumber,
    String? assetVariant,
    bool? showLoanId,
    String? loanId,
    String? assignedBy,
    int? assignmentId,
    Assignment? assignment,
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
      loanId: loanId ?? this.loanId,
      assignedAgentName: assignedAgentName ?? this.assignedAgentName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignmentId: assignmentId ?? this.assignmentId,
      assignment: assignment ?? this.assignment,
    );
  }

  static String _mapAssignmentStatus(String? status) {
    if (status == null) return 'Assigned';
    final s = status.toLowerCase();
    if (s == 'in progress' || s == 'pending_verification' || s == 'pending') {
      return 'Pending';
    } else if (s == 'completed' || s == 'paid') {
      return 'Completed';
    } else if (s == 'rejected') {
      return 'Rejected';
    } else if (s == 'closed') {
      return 'Closed';
    }
    return 'Assigned';
  }

  factory Customer.fromJson(Map<String, dynamic> body) {
    final json = body['data'] as Map<String, dynamic>? ?? {};
    final assignment = (body.containsKey('assignment_id') || body.containsKey('assignmentId'))
        ? Assignment.fromJson(body)
        : null;

    final String assignedAgentId = assignment != null
        ? assignment.agentId.toString()
        : (json['assignedAgentId']?.toString() ??
            (body['agent'] as Map?)?['agent_id']?.toString() ??
            body['agent_id']?.toString() ?? '');

    final String assignedAgentName = assignment != null
        ? assignment.agentName
        : (json['assignedAgentName']?.toString() ??
            (body['agent'] as Map?)?['full_name']?.toString() ?? '');

    final String status = assignment != null
        ? assignment.status
        : _mapAssignmentStatus(
            body['assignment_status'] as String? ?? body['status'] as String?,
          );

    return Customer(
      id: body['record_id']?.toString() ?? json['id']?.toString() ?? body['id']?.toString() ?? '',
      name: (json['customer_name']?.toString() ?? '').isNotEmpty
          ? json['customer_name'].toString()
          : (json['name']?.toString() ?? ''),
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      overdueDays: (json['overdueDays'] as num?)?.toInt() ?? 0,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      priority: json['priority'] as String? ?? 'MEDIUM',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      assignedAgentId: assignedAgentId,
      assignedAgentName: assignedAgentName,
      status: status,
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (body['remarks'] != null ? [body['remarks'].toString()] : const []),
      scheduledVisit: json['scheduledVisit'] != null
          ? DateTime.tryParse(json['scheduledVisit'].toString())
          : (body['schedule_date'] != null
              ? DateTime.tryParse(body['schedule_date'].toString())
              : null),
      assetModel: json['assetModel'] as String? ?? '',
      assetRegNo: json['assetRegNo'] as String? ?? '',
      engineNumber: json['engineNumber'] as String? ?? '',
      chasisNumber: json['chasisNumber'] as String? ?? '',
      assetVariant: json['assetVariant'] as String? ?? '',
      showLoanId: json['showLoanId'] as bool? ?? true,
      loanId: json['loanId']?.toString() ?? json['loadId']?.toString() ?? '',
      assignedBy: assignment != null
          ? assignment.assignedBy.toString()
          : ((body['assigned_by'] ?? json['assigned_by'])?.toString() ?? ''),
      assignmentId: assignment?.assignmentId ??
          (body['assignment_id'] ??
              json['assignment_id'] ??
              body['assignmentId'] ??
              json['assignmentId']) as int?,
      assignment: assignment,
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
      'assignedBy': assignedBy,
      'assignmentId': assignmentId,
      'assignment': assignment?.toJson(),
    };
  }
}
