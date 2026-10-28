import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import 'widgets/animated_background.dart';
import 'widgets/login_form.dart';
import 'widgets/register_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  void _goHome(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.check_circle_outline, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(message))]),
        backgroundColor: const Color(0xFF075B47),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  void _goLoginAfterRegistration(String message) {
    setState(() => _showLogin = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.mark_email_read_outlined, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(message))]),
        backgroundColor: const Color(0xFF075B47),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 650;
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(narrow ? 20 : 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: EdgeInsets.all(narrow ? 24 : 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFA),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Color(0x5500150E), blurRadius: 38, offset: Offset(0, 18))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [Color(0xFF0D775A), Color(0xFF064939)]),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('NaturaGrid', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF064939))),
                      const SizedBox(height: 6),
                      Text(_showLogin ? 'Deje de estar tragando mierda' : 'Crea tu espacio de innovación sostenible.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF668078), height: 1.35)),
                      const SizedBox(height: 26),
                      _AuthToggle(login: _showLogin, onChanged: (value) => setState(() => _showLogin = value)),
                      const SizedBox(height: 26),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(animation), child: child)),
                        child: _showLogin
                            ? LoginForm(key: const ValueKey('login'), onSuccess: _goHome)
                            : RegisterForm(key: const ValueKey('register'), onRegistered: _goLoginAfterRegistration),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthToggle extends StatelessWidget {
  const _AuthToggle({required this.login, required this.onChanged});
  final bool login;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFE8F0EB), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [_item('Iniciar sesión', true), _item('Crear cuenta', false)]),
    );
  }

  Widget _item(String label, bool value) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: login == value ? const Color(0xFF075B47) : Colors.transparent, borderRadius: BorderRadius.circular(11)),
        child: Text(label, style: TextStyle(color: login == value ? Colors.white : const Color(0xFF527168), fontWeight: FontWeight.w700)),
      ),
    ),
  );
}
