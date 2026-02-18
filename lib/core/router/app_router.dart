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
    initialLocation: '/',
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
