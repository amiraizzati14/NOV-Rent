import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nov_rent/screens/user/favorite_screen.dart';
import 'package:nov_rent/screens/user/pesanan_screen.dart';
import '../screens/user/home_screen.dart';
import '../screens/user/katalog_screen.dart';
import '../screens/user/account_screen.dart';
import '../screens/user/detail_screen.dart';
import '../screens/user/ringkasan_pesanan_screen.dart';
import '../screens/user/konfirmasi_pembayaran_screen.dart';
import '../screens/login_screen.dart';
import '../widget/main_shell.dart';
import '../screens/register_screen.dart';
import '../screens/Admin/admin_dashboard_screen.dart';
import '../screens/Admin/armada_screen.dart';
import '../screens/Admin/admin_shell.dart';
import '../screens/Admin/manajemen_sopir_screen.dart';
import '../screens/Admin/admin_detail_pesanan_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/armada',
          builder: (context, state) => const ArmadaScreen(),
        ),
        GoRoute(
          path: '/admin/pesanan',
          builder: (context, state) => const AdminPlaceholderScreen(title: 'Pesanan', icon: Icons.assignment_outlined),
        ),

        GoRoute(
        path: '/admin/driver',
        builder: (context, state) => const ManajemenSopirScreen(),
        ),
      ],
    ),

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/favorite',
          builder: (context, state) => const FavoriteScreen(),
        ),
        GoRoute(
          path: '/pesanan',
          builder: (context, state) => const PesananScreen(),
        ),
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountScreen(),
        ),
      ],
    ),

    GoRoute(
      path: '/detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;

        return DetailScreen(
          carId: id,
        );
      },
    ),
    GoRoute(
      path: '/ringkasan-pesanan/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final withDriver = state.uri.queryParameters['withDriver'] == 'true';

        return RingkasanPesananScreen(
          carId: id,
          withDriver: withDriver,
        );
      },
    ),
    GoRoute(
      path: '/konfirmasi-pembayaran',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return KonfirmasiPembayaranScreen(
          data: data,
        );
      },
    ),
    GoRoute(
      path: '/admin/pesanan/:orderId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;

        return AdminDetailPesananScreen(
          orderId: orderId,
        );
      },
    ),
  ],
);
