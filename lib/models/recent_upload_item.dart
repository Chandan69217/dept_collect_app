import 'package:dept_collection_app/constants/app_constants.dart';

class RecentUploadItem {
  final int fileId;
  final String fileName;
  final String? uploadedBy;
  final String? agentId;
  final int totalRecords;
  final String status;
  final DateTime createdAt;

  RecentUploadItem({
    required this.fileId,
    required this.fileName,
    this.uploadedBy,
    this.agentId,
    this.status = "success",
    required this.totalRecords,
    required this.createdAt,
  });

  String get formattedDate => AppConstants.dateFormat.format(createdAt);

  factory RecentUploadItem.fromJson(Map<String, dynamic> json) {
    return RecentUploadItem(
      fileId: json['file_id'],
      fileName: json['file_name'],
      uploadedBy: json['uploaded_by'],
      agentId: json['agent_id'],
      status: json['status'] ?? 'success',
      totalRecords: json['total_records'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
