import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _loggedInKey = 'is_logged_in';
  static const String _emailKey = 'auth_email';

  static Future<void> saveSession(String token, String? email) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_loggedInKey, true);
    if (email != null) await prefs.setString(_emailKey, email);
  }

  static Future<String?> getEmail() async =>
      (await SharedPreferences.getInstance()).getString(_emailKey);

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.setBool(_loggedInKey, false);
  }
}
