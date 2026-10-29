import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/katalog_screen.dart';
import '../screens/account_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/login_screen.dart';
import '../widget/main_shell.dart';

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
          path: '/katalog',
          builder: (context, state) => const KatalogScreen(),
        ),
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/detail/:id',
      parentNavigatorKey: _rootNavigatorKey, // Menyembunyikan Bottom Nav
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DetailScreen(carId: id);
      },
    ),
  ],
);