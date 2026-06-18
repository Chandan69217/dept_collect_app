import 'dart:convert';
import 'dart:developer';
import 'package:dept_collection_app/constants/app_constants.dart';
import 'package:dept_collection_app/services/database_service.dart';
import 'package:dept_collection_app/services/shared_prefs_service.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    required bool isAdmin,
  }) async {
    final endpoint = isAdmin
        ? ApiConstants.adminLogin
        : ApiConstants.agentLogin;
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      final isSuccess = responseData['isSuccess'] == true;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          isSuccess) {
        return responseData;
      } else if (response.statusCode == 200 && !isSuccess) {
        final message = responseData['message'] == "Invalid Password"
            ? "Incorrect password. Please try again."
            : responseData['message'] == "Invalid Email"
            ? "Incorrect email. Please try with different email"
            : "Please contact your administrator";
        throw Exception(message);
      } else {
        final message =
            responseData['message'] ??
            'Authentication failed (Status ${response.statusCode})';
        throw Exception(message);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }

  Future<Map<String, dynamic>> createAgent({
    required int adminId,
    required String fullName,
    required String email,
    required String mobile,
    required String password,
    required String region,
    required Map<String, bool> permissions,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createAgent}');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer ${SharedPrefsService.getToken()}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'admin_id': adminId,
          'full_name': fullName,
          'email': email,
          'mobile': mobile,
          'password': password,
          'region': region,
          'permission': permissions,
        }),
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      final isSuccess = responseData['isSuccess'] ?? false;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          isSuccess) {
        return responseData;
      } else {
        final message =
            responseData['message'] ?? 'Failed to create agent profile.';
        throw Exception(message);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllAgents() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getAllAgents}',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer ${SharedPrefsService.getToken()}',
          'Accept': 'application/json',
        },
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      final isSuccess = responseData['isSuccess'] ?? false;
      if (response.statusCode == 200 && isSuccess) {
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        final message =
            responseData['message'] ?? 'Failed to load agents list.';
        throw Exception(message);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }

  Future<Map<String, dynamic>> updateAgent({
    required String agentId,
    String? fullName,
    String? email,
    String? mobile,
    String? status,
    String? region,
    Map<String, bool>? permissions,
  }) async {
    final db = DatabaseService();
    final isUpdatingOwnAdminProfile =
        (db.currentUser != null &&
        db.currentUser!.id == agentId &&
        db.currentRole.toUpperCase() == AppConstants.roleAdmin);

    final url = Uri.parse(
      isUpdatingOwnAdminProfile
          ? '${ApiConstants.baseUrl}${ApiConstants.updateAdminProfile}$agentId'
          : '${ApiConstants.baseUrl}${ApiConstants.updateAgentProfile}$agentId',
    );

    try {
      final Map<String, dynamic> body = {};
      if (fullName != null) body['full_name'] = fullName;
      if (email != null) body['email'] = email;
      if (mobile != null) body['mobile'] = mobile;
      if (status != null) body['status'] = status;
      if (region != null) body['region'] = region;
      if (permissions != null) body['permission'] = permissions;

      final response = await _client.put(
        url,
        headers: {
          'Authorization': 'Bearer ${SharedPrefsService.getToken()}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      Map<String, dynamic> responseData;

      try {
        responseData = jsonDecode(response.body);
        log("Body: ${responseData}");
      } catch (_) {
        responseData = {
          "isSuccess": false,
          "message": "Failed to decode response from server.",
        };
      }

      final isSuccess =
          responseData['isSuccess'] == true || responseData['success'] == true;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          isSuccess) {
        return responseData;
      } else {
        final message =
            responseData['message'] ?? 'Failed to update agent profile.';
        throw Exception(message);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }

  // File uploads related

  Future<List<Map<String, dynamic>>> getRecentUploads() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getAllExcelFiles}',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer ${SharedPrefsService.getToken()}',
          'Accept': 'application/json',
        },
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      final isSuccess = responseData['success'] ?? false;
      if (response.statusCode == 200 && isSuccess) {
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        final message =
            responseData['message'] ?? 'Failed to load excels files.';
        throw Exception(message);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }


  Future<List<Map<String, dynamic>>> getFileRecords({required int fileId, required int limits}) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getAllExcelRecords}/$fileId?page=1&limit=$limits',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer ${SharedPrefsService.getToken()}',
          'Accept': 'application/json',
        },
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      final isSuccess = responseData['success'] ?? false;
      if (response.statusCode == 200 && isSuccess) {
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        final message =
            responseData['message'] ?? 'Failed to load excel files records.';
        throw Exception(message);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadRecords(
    String fileName,
    List<Map<String, dynamic>> records,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.uploadFileRecords}',
    );

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer ${SharedPrefsService.getToken()}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'fileName': fileName, 'records': records}),
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      final isSuccess =
          responseData['success'] == true || responseData['isSuccess'] == true;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          isSuccess) {
        return responseData;
      } else {
        final message =
            responseData['message'] ?? 'Failed to upload records to API.';
        throw Exception(message);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }


  Future<Map<String, dynamic>> deleteFileRecord({
    required int fileId,
    required String recordId,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.deleteExcelFileRecord}/$recordId',
    );

    try {
      final response = await _client.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${SharedPrefsService.getToken()}',
          'Accept': 'application/json',
        },
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      final isSuccess = responseData['success'] == true || responseData['isSuccess'] == true;
      if (response.statusCode == 200 && isSuccess) {
        return responseData;
      } else {
        final message = responseData['message'] ?? 'Failed to delete record from API.';
        throw Exception(message);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }

  Future<Map<String, dynamic>> deleteFile(int fileId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.deleteExcelFile}/$fileId',
    );

    try {
      final response = await _client.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${SharedPrefsService.getToken()}',
          'Accept': 'application/json',
        },
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      final isSuccess = responseData['success'] == true || responseData['isSuccess'] == true;
      if (response.statusCode == 200 && isSuccess) {
        return responseData;
      } else {
        final message = responseData['message'] ?? 'Failed to delete file from API.';
        throw Exception(message);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network or server error: $e');
    }
  }
}
