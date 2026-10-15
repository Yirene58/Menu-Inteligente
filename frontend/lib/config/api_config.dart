class ApiConfig {
  // Backend Quarkus
  // Para un dispositivo físico, use la IP de la máquina que ejecuta Quarkus.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Endpoint de autenticación
  static const String loginEndpoint = '/auth/login';

  // Endpoint de registro
  static const String registerEndpoint = '/auth/register';

  static String get loginUrl => '$baseUrl$loginEndpoint';

  static String get registerUrl => '$baseUrl$registerEndpoint';
  static String get validateUrl => '$baseUrl/auth/validate';
  static String get logoutUrl => '$baseUrl/auth/logout';
}
