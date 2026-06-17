class RecoveryUpload {
  final String fileName;
  final String uploadedBy;
  final List<RecoveryRecord> records;

  const RecoveryUpload({
    this.fileName = '',
    this.uploadedBy = '',
    this.records = const [],
  });

  /// Factory constructor to create a RecoveryUpload from a Map/JSON.
  /// Fully null-value safe.
  factory RecoveryUpload.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RecoveryUpload();
    }

    final recordsList = json['records'] as List?;
    final parsedRecords = recordsList != null
        ? recordsList
            .map((e) => RecoveryRecord.fromJson(e as Map<String, dynamic>?))
            .toList()
        : const <RecoveryRecord>[];

    return RecoveryUpload(
      fileName: json['fileName'] as String? ?? '',
      uploadedBy: json['uploadedBy'] as String? ?? '',
      records: parsedRecords,
    );
  }

  /// Converts the RecoveryUpload instance into a Map/JSON.
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'uploadedBy': uploadedBy,
      'records': records.map((e) => e.toJson()).toList(),
    };
  }

  /// Creates a copy of this class with the given fields replaced.
  RecoveryUpload copyWith({
    String? fileName,
    String? uploadedBy,
    List<RecoveryRecord>? records,
  }) {
    return RecoveryUpload(
      fileName: fileName ?? this.fileName,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      records: records ?? this.records,
    );
  }
}

class RecoveryRecord {
  final String name;
  final String assetRegNo;
  final String engineNumber;
  final String chasisNumber;
  final String assetVariant;
  final String assetModel;
  final double amountDue;
  final int overdueDays;
  final String address;
  final String phone;
  final String priority;

  const RecoveryRecord({
    this.name = '',
    this.assetRegNo = '',
    this.engineNumber = '',
    this.chasisNumber = '',
    this.assetVariant = '',
    this.assetModel = '',
    this.amountDue = 0.0,
    this.overdueDays = 0,
    this.address = '',
    this.phone = '',
    this.priority = '',
  });

  /// Factory constructor to create a RecoveryRecord from a Map/JSON.
  /// Fully null-value safe.
  factory RecoveryRecord.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RecoveryRecord();
    }

    return RecoveryRecord(
      name: json['name'] as String? ?? '',
      assetRegNo: json['assetRegNo'] as String? ?? '',
      engineNumber: json['engineNumber'] as String? ?? '',
      chasisNumber: json['chasisNumber'] as String? ?? '',
      assetVariant: json['assetVariant'] as String? ?? '',
      assetModel: json['assetModel'] as String? ?? '',
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0.0,
      overdueDays: (json['overdueDays'] as num?)?.toInt() ?? 0,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
    );
  }

  /// Converts the RecoveryRecord instance into a Map/JSON.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'assetRegNo': assetRegNo,
      'engineNumber': engineNumber,
      'chasisNumber': chasisNumber,
      'assetVariant': assetVariant,
      'assetModel': assetModel,
      'amountDue': amountDue,
      'overdueDays': overdueDays,
      'address': address,
      'phone': phone,
      'priority': priority,
    };
  }

  /// Creates a copy of this class with the given fields replaced.
  RecoveryRecord copyWith({
    String? name,
    String? assetRegNo,
    String? engineNumber,
    String? chasisNumber,
    String? assetVariant,
    String? assetModel,
    double? amountDue,
    int? overdueDays,
    String? address,
    String? phone,
    String? priority,
  }) {
    return RecoveryRecord(
      name: name ?? this.name,
      assetRegNo: assetRegNo ?? this.assetRegNo,
      engineNumber: engineNumber ?? this.engineNumber,
      chasisNumber: chasisNumber ?? this.chasisNumber,
      assetVariant: assetVariant ?? this.assetVariant,
      assetModel: assetModel ?? this.assetModel,
      amountDue: amountDue ?? this.amountDue,
      overdueDays: overdueDays ?? this.overdueDays,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      priority: priority ?? this.priority,
    );
  }
}
