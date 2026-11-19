import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, required this.onRegistered});
  final ValueChanged<String> onRegistered;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _organization = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _organization.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu correo electrónico.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) return 'Escribe un correo válido.';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.length < 8) return 'Usa mínimo 8 caracteres.';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value)) return 'Incluye letras y números.';
    return null;
  }

  String? _confirmValidator(String? value) {
    if (value != _password.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final result = await AuthService().register(email: _email.text.trim(), password: _password.text, name: _name.text, organization: _organization.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!result.success) {
      _showError(result.message);
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(children: [CircleAvatar(radius: 28, backgroundColor: Color(0xFFE0F2E9), child: Icon(Icons.check_rounded, size: 34, color: Color(0xFF075B47))), SizedBox(height: 14), Text('¡Cuenta creada!')]),
        content: const Text('Tu cuenta está lista. Te enviamos un correo de bienvenida con los siguientes pasos.', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Continuar'))],
      ),
    );
    if (mounted) widget.onRegistered('Cuenta creada. Inicia sesión con tus credenciales.');
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(message))]), backgroundColor: const Color(0xFFB42318), behavior: SnackBarBehavior.floating),
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(controller: _name, textInputAction: TextInputAction.next, validator: (value) => value == null || value.trim().length < 2 ? 'Escribe tu nombre completo.' : null, decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline_rounded))),
        const SizedBox(height: 16),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, validator: _emailValidator, decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline_rounded))),
        const SizedBox(height: 16),
        TextFormField(controller: _password, obscureText: _obscurePassword, textInputAction: TextInputAction.next, validator: _passwordValidator, decoration: InputDecoration(labelText: 'Contraseña', helperText: 'Mínimo 8 caracteres, letras y números', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => _obscurePassword = !_obscurePassword), icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
        const SizedBox(height: 16),
        TextFormField(controller: _confirm, obscureText: _obscureConfirm, textInputAction: TextInputAction.done, validator: _confirmValidator, onFieldSubmitted: (_) => _submit(), decoration: InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: const Icon(Icons.verified_user_outlined), suffixIcon: IconButton(onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm), icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Crear cuenta')),
      ]),
    );
  }
}
