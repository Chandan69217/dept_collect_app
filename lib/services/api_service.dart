import 'dart:convert';
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
        }),
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = {};
      }

      final isSuccess = responseData['success'] == true;
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

      final isSuccess = responseData['isSuccess']??false;
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
  }) async {
    final url = Uri.parse(
      DatabaseService().currentRole.toUpperCase() == AppConstants.roleAdmin ?'${ApiConstants.baseUrl}${ApiConstants.updateAdminProfile}${agentId}' :'${ApiConstants.baseUrl}${ApiConstants.updateAgentProfile}${agentId}',
    );

    try {

      final Map<String, dynamic> body = {};
      if (fullName != null) body['full_name'] = fullName;
      if (email != null) body['email'] = email;
      if (mobile != null) body['mobile'] = mobile;
      if (status != null) body['status'] = status;

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
      } catch (_) {
        responseData = {
          "isSuccess": false,
          "message": "Failed to decode response from server.",
        };
      }


      final isSuccess = responseData['isSuccess']??false;
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
}
