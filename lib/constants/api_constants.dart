class ApiConstants {
  static const String baseUrl = 'https://api.financeoil24hours.com';
  static const String agentLogin = '/api/agent/login';
  static const String adminLogin = '/api/admin/login';
  static const String createAgent = '/api/agent/create';
  static const String getAllAgents = '/api/agent/get_all';
  static const String updateAgentProfile = '/api/agent/update';
  static const String updateAdminProfile = '/api/admin/update';
  static const String uploadFileRecords = '/api/excel-file/create';
  static const String getAllExcelFiles = '/api/excel-file/files';
  static const String getAllExcelRecords = '/api/excel-file/records';
  static const String deleteExcelFileRecord = '/api/excel-file/record';
  static const String deleteExcelFile = '/api/excel-file/file';
  static const String createAssignment = '/api/assignments/create';
  static const String getAllAssignments = '/api/assignments/all';
  static const String getAgentAssignments = '/api/assignments/agent';
  static const String getAllAgentAssignments = '/api/assignments/all';
  static const String updateRecordPriority = '/api/excel-file/record-status';
}
