import 'dart:convert';
import 'dart:developer';

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
          'correo': email.trim(),
          'contrasena': password,
        }),
      ).timeout(const Duration(seconds: 12));

      Map<String, dynamic> data = {};

      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          log('Error parseando respuesta de login: $e');
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

      return LoginResponse(
        success: false, 
        message: data['mensaje'] ?? 'No fue posible iniciar sesión'
      );
    } catch (e) {
      log('Error en login: $e');
      return LoginResponse(
        success: false,
        message: 'No se pudo conectar con el servidor',
      );
    }
  }

  Future<LoginResponse> register({
    required String email, 
    required String password, 
    required String name, 
    String? organization
  }) async {
    return _sendCredentials(
      ApiConfig.registerUrl, 
      email, 
      password, 
      name: name, 
      organization: organization, 
      saveSession: false
    );
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
      final response = await http.post(
        Uri.parse(url), 
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json',
        }, 
        body: jsonEncode({
          'correo': email.trim(), 
          'contrasena': password, 
          if (name != null) 'nombre': name.trim(), 
          if (organization != null && organization.trim().isNotEmpty) 'organizacion': organization.trim()
        })
      ).timeout(const Duration(seconds: 12));

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          log('Error al convertir JSON de respuesta: $e');
        }
      }

      // Si la respuesta es exitosa (200, 201)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = LoginResponse.fromJson({...data, 'success': true});
        if (saveSession && result.token != null) {
          await StorageService.saveSession(result.token!, result.email);
        }
        return result;
      }

      // Si el servidor devuelve 400, 409, etc., retornamos el mensaje exacto del backend Java
      final mensajeError = data['mensaje'] ?? 'No fue posible procesar la solicitud (${response.statusCode})';
      return LoginResponse(success: false, message: mensajeError);

    } catch (e) {
      log('Error de red/petición en _sendCredentials: $e');
      return LoginResponse(
        success: false, 
        message: 'Error de conexión con el servidor. Revisa tu red.'
      );
    }
  }

  Future<bool> validateSession() async {
    final token = await StorageService.getToken();
    if (token == null) return false;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.validateUrl), 
        headers: {'Authorization': 'Bearer $token'}
      ).timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) { 
      log('Error validando sesión: $e');
      return false; 
    }
  }

  Future<void> logout() async {
    final token = await StorageService.getToken();
    if (token != null) {
      try { 
        await http.post(
          Uri.parse(ApiConfig.logoutUrl), 
          headers: {'Authorization': 'Bearer $token'}
        ).timeout(const Duration(seconds: 8)); 
      } catch (e) {
        log('Error en logout: $e');
      }
    }
    await StorageService.logout();
  }
}