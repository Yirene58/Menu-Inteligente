import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/login_response.dart';
import 'storage_service.dart';

class AuthService {
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'correo': email,
          'contrasena': password,
        }),
      ).timeout(const Duration(seconds: 12));

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          return LoginResponse(
            success: false,
            message: 'Credenciales incorrectas',
          );
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = LoginResponse.fromJson({
          ...data,
          'success': true,
        });

        if (result.token != null && result.token!.isNotEmpty) {
          await StorageService.saveSession(result.token!, result.email);
        }

        return result;
      }

      return LoginResponse(success: false, message: data['mensaje'] ?? 'No fue posible iniciar sesión');
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'No se pudo conectar con el servidor',
      );
    }
  }

  Future<LoginResponse> register({required String email, required String password, required String name, String? organization}) async {
    return _sendCredentials(ApiConfig.registerUrl, email, password, name: name, organization: organization, saveSession: false);
  }

  Future<LoginResponse> _sendCredentials(
    String url,
    String email,
    String password, {
    String? name,
    String? organization,
    bool saveSession = true,
  }) async {
    try {
      final response = await http.post(Uri.parse(url), headers: {
        'Content-Type': 'application/json', 'Accept': 'application/json',
      }, body: jsonEncode({'correo': email.trim(), 'contrasena': password, if (name != null) 'nombre': name.trim(), if (organization != null && organization.trim().isNotEmpty) 'organizacion': organization.trim()}))
          .timeout(const Duration(seconds: 12));
      final data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = LoginResponse.fromJson({...data, 'success': true});
        if (saveSession && result.token != null) {
          await StorageService.saveSession(result.token!, result.email);
        }
        return result;
      }
      return LoginResponse(success: false, message: data['mensaje'] ?? 'No fue posible crear la cuenta');
    } catch (_) {
      return LoginResponse(success: false, message: 'No se pudo conectar con el servidor. Inténtalo de nuevo.');
    }
  }

  Future<bool> validateSession() async {
    final token = await StorageService.getToken();
    if (token == null) return false;
    try {
      final response = await http.get(Uri.parse(ApiConfig.validateUrl), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<void> logout() async {
    final token = await StorageService.getToken();
    if (token != null) {
      try { await http.post(Uri.parse(ApiConfig.logoutUrl), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 8)); } catch (_) { }
    }
    await StorageService.logout();
  }
}
