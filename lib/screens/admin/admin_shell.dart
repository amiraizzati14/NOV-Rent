import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({required this.child, super.key});

  final Widget child;
  static const blue = Color(0xFF0755C9);
  static const ink = Color(0xFF182238);
  static const muted = Color(0xFF697184);
  static const surface = Color(0xFFF8F9FE);

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Column(children: [
          _header(context),
          Expanded(child: child),
          _bottomBar(context, location),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NOV RENT', style: TextStyle(color: blue, fontSize: 15, fontWeight: FontWeight.w800)),
            Text('ADMIN HUB • DASHBOARD', style: TextStyle(color: muted, fontSize: 10, letterSpacing: .7)),
          ])),
          Stack(children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: ink, size: 25)),
            Positioned(right: 7, top: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
          ]),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'logout', child: Text('Keluar'))],
            child: const CircleAvatar(radius: 18, backgroundColor: Color(0xFFD9E3F8), child: Icon(Icons.person, color: blue)),
          ),
        ]),
      );

  Widget _bottomBar(BuildContext context, String location) => Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 12),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEF0F4)))),
        child: Row(children: [
          _navItem(context, location, '/admin', 'Dashboard', Icons.dashboard_outlined),
          _navItem(context, location, '/admin/armada', 'Armada', Icons.directions_car_outlined),
          _navItem(context, location, '/admin/pesanan', 'Pesanan', Icons.assignment_outlined),
          _navItem(context, location, '/admin/driver', 'Driver', Icons.person_outline_rounded),
        ]),
      );

  Widget _navItem(BuildContext context, String location, String path, String label, IconData icon) {
    final active = path == '/admin' ? location == '/admin' : location.startsWith(path);
    return Expanded(child: InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? blue : muted, size: 22),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: active ? blue : muted, fontWeight: FontWeight.w700)),
      ]),
    ));
  }
}

class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: AdminShell.blue),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AdminShell.ink)),
        const SizedBox(height: 6),
        const Text('Halaman admin sedang disiapkan.', style: TextStyle(color: AdminShell.muted)),
      ]));
}
