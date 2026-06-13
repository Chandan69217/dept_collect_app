import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String keyToken = 'auth_token';
  static const String keyUserData = 'user_data';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyLastLoginMode = 'last_login_mode';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception("SharedPrefsService is not initialized. Call init() first.");
    }
    return _prefs!;
  }

  // Token
  static Future<bool> saveToken(String token) async {
    return await prefs.setString(keyToken, token);
  }

  static String? getToken() {
    return prefs.getString(keyToken);
  }

  // User Data (Map)
  static Future<bool> saveUserData(Map<String, dynamic> data) async {
    final String jsonStr = jsonEncode(data);
    return await prefs.setString(keyUserData, jsonStr);
  }

  static Map<String, dynamic>? getUserData() {
    final String? jsonStr = prefs.getString(keyUserData);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Is Logged In
  static Future<bool> saveIsLoggedIn(bool value) async {
    return await prefs.setBool(keyIsLoggedIn, value);
  }

  static bool isLoggedIn() {
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }

  // Last Login Mode
  static Future<bool> saveLastLoginMode(String mode) async {
    return await prefs.setString(keyLastLoginMode, mode);
  }

  static String? getLastLoginMode() {
    return prefs.getString(keyLastLoginMode);
  }

  // Clear session keys only (preserving settings/last login mode)
  static Future<bool> clear() async {
    await prefs.remove(keyToken);
    await prefs.remove(keyUserData);
    return await prefs.remove(keyIsLoggedIn);
  }
}
