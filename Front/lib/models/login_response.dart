class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final String? email;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.email,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['mensaje'] ?? json['message'] ?? '',
      token: json['token'],
      email: json['correo'],
    );
  }
}
