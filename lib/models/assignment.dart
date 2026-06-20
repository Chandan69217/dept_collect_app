class Assignment {
  final int assignmentId;
  final int recordId;
  final int agentId;
  final String agentName;
  final int assignedBy;
  final DateTime? scheduleDate;
  final String remarks;
  final double paymentCollection;
  final String paymentMethod;
  final String approvedImg;
  final String status; // 'Assigned', 'Pending', 'Completed', 'Rejected', 'Closed'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? recordData;
  final Map<String, dynamic>? fileData;

  const Assignment({
    required this.assignmentId,
    required this.recordId,
    required this.agentId,
    required this.agentName,
    required this.assignedBy,
    this.scheduleDate,
    required this.remarks,
    required this.paymentCollection,
    required this.paymentMethod,
    required this.approvedImg,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.recordData,
    this.fileData,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    final agentMap = json['agent'] as Map<String, dynamic>?;
    final dataMap = json['data'] as Map<String, dynamic>?;
    final fileMap = json['file'] as Map<String, dynamic>?;

    return Assignment(
      assignmentId: (json['assignment_id'] ?? json['assignmentId']) as int? ?? 0,
      recordId: (json['record_id'] ?? json['recordId']) as int? ?? 0,
      agentId: (agentMap?['agent_id'] ?? json['agent_id'] ?? json['agentId']) as int? ?? 0,
      agentName: (agentMap?['full_name'] ?? json['agent_name'] ?? '') as String,
      assignedBy: (json['assigned_by'] ?? json['assignedBy']) as int? ?? 0,
      scheduleDate: json['schedule_date'] != null
          ? DateTime.tryParse(json['schedule_date'].toString())
          : null,
      remarks: (json['remarks'] ?? '') as String,
      paymentCollection: (json['payment_collection'] ?? json['paymentCollection'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: (json['payment_method'] ?? json['paymentMethod'] ?? 'Cash') as String,
      approvedImg: (json['approved_img'] ?? json['approvedImg'] ?? '') as String,
      status: (json['assignment_status'] ?? json['status'] ?? 'Assigned') as String,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      recordData: dataMap,
      fileData: fileMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'record_id': recordId,
      'agent_id': agentId,
      'agent_name': agentName,
      'assigned_by': assignedBy,
      'schedule_date': scheduleDate?.toIso8601String(),
      'remarks': remarks,
      'payment_collection': paymentCollection,
      'payment_method': paymentMethod,
      'approved_img': approvedImg,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'data': recordData,
      'file': fileData,
    };
  }
}
