import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:food_ai/features/home/home_screen.dart';
import 'package:food_ai/features/camera/camera_screen.dart';
import 'package:food_ai/features/profile/profile_screen.dart';
import 'package:food_ai/features/dish_detail/dish_detail_screen.dart';
import 'package:food_ai/features/camera/add_dish_no_photo_screen.dart';
import 'package:food_ai/features/auth/login_screen.dart';
import 'package:food_ai/features/auth/register_screen.dart';
import 'package:food_ai/core/auth/auth_notifier.dart';
import 'package:food_ai/services/supabase_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter([AuthNotifier? authNotifier]) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      if (!isSupabaseConfigured || authNotifier == null) return null;
      final loc = state.matchedLocation;
      final loggedIn = authNotifier.user != null;
      if (loggedIn && (loc == '/login' || loc == '/register')) return '/';
      if (!loggedIn && loc != '/login' && loc != '/register') return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          child: SplashScreen(authNotifier: authNotifier),
        ),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: RegisterScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'dish/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return MaterialPage(
                        child: DishDetailScreen(dishId: id),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'add-no-photo',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final date = state.uri.queryParameters['date'];
                      return MaterialPage(
                        child: AddDishNoPhotoScreen(selectedDate: date),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/camera',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CameraScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.authNotifier});

  final AuthNotifier? authNotifier;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final authNotifier = widget.authNotifier;
    String target;
    if (!isSupabaseConfigured || authNotifier == null) {
      target = '/';
    } else {
      target = authNotifier.user != null ? '/' : '/login';
    }
    if (mounted) {
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _SplashLogo(),
                SizedBox(height: 24),
                Text(
                  'FOOD AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 8),
                Opacity(
                  opacity: 0.7,
                  child: Text(
                    'INITIALIZING',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Фото',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
