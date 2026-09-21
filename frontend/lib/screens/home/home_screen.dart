import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../auth/auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  Future<void> _logout(BuildContext context) async { await AuthService().logout(); if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false); }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FBF8),
    appBar: AppBar(backgroundColor: const Color(0xFFF7FBF8), surfaceTintColor: Colors.transparent, title: const Row(children: [_Mark(small: true), SizedBox(width: 10), Text('NaturaGrid', style: TextStyle(color: Color(0xFF093C36), fontWeight: FontWeight.w800))]), actions: [IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout_rounded), color: const Color(0xFF0C6655))]),
    body: FutureBuilder<String?>(future: StorageService.getEmail(), builder: (context, snapshot) => ListView(padding: const EdgeInsets.all(24), children: [
      Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF075C4D), Color(0xFF16826A)]), borderRadius: BorderRadius.circular(28)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _Mark(), const SizedBox(height: 22), Text('Hola, ${snapshot.data?.split('@').first ?? 'explorador'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 29)), const SizedBox(height: 8), const Text('Tu centro para crear impacto positivo empieza aquí.', style: TextStyle(color: Color(0xFFE3F7EA), fontSize: 16))])),
      const SizedBox(height: 26), const Text('Explora tu espacio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF093C36))), const SizedBox(height: 14),
      const Wrap(spacing: 14, runSpacing: 14, children: [_MenuCard(icon: Icons.insights_rounded, title: 'Impacto', subtitle: 'Mide tus avances', color: Color(0xFF4A9A70)), _MenuCard(icon: Icons.lightbulb_outline_rounded, title: 'Ideas verdes', subtitle: 'Inspírate y crea', color: Color(0xFFF2AA4C)), _MenuCard(icon: Icons.groups_rounded, title: 'Comunidad', subtitle: 'Conecta y colabora', color: Color(0xFF4785A3)), _MenuCard(icon: Icons.auto_awesome_rounded, title: 'Laboratorio', subtitle: 'Próximamente', color: Color(0xFF8B70BA))]),
    ])),
  );
}
class _Mark extends StatelessWidget { const _Mark({this.small = false}); final bool small; @override Widget build(BuildContext context) => Container(width: small ? 34 : 64, height: small ? 34 : 64, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFB5E85A), Color(0xFF33B988)])), child: Icon(Icons.bolt_rounded, color: const Color(0xFF064236), size: small ? 20 : 38)); }
class _MenuCard extends StatelessWidget { const _MenuCard({required this.icon, required this.title, required this.subtitle, required this.color}); final IconData icon; final String title, subtitle; final Color color; @override Widget build(BuildContext context) => SizedBox(width: 180, child: Material(color: Colors.white, borderRadius: BorderRadius.circular(22), child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title estará disponible pronto'), behavior: SnackBarBehavior.floating)), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(backgroundColor: color.withValues(alpha: .15), child: Icon(icon, color: color)), const SizedBox(height: 18), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF093C36))), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFF718880), fontSize: 12))]))))); }
