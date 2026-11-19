import 'package:flutter/material.dart';

import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const GestorTecnoApp());
}

class GestorTecnoApp extends StatelessWidget {
  const GestorTecnoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GestorTecno',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.theme,

      home: const AppStartup(),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool loading = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();

    _checkSession();
  }

  Future<void> _checkSession() async {
    final localSession = await StorageService.isLoggedIn();
    final session = localSession && await AuthService().validateSession();
    if (localSession && !session) await StorageService.logout();

    if (!mounted) return;

    setState(() {
      loggedIn = session;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (loggedIn) {
      return const HomeScreen();
    }

    return const AuthScreen();
  }
}
