import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_wrapper.dart';
import '../screens/dashboard_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/add_event_screen.dart';
import '../screens/edit_event_screen.dart';
import '../screens/view_participants_screen.dart';
import '../screens/scroll_mode_screen.dart';
import '../models/event_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (authState.isLoading || isSplash) return null; // Let splash screen handle delay

      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainWrapper(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ]
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EventDetailScreen(event: event);
        },
      ),
      GoRoute(
        path: '/create_event',
        builder: (context, state) => const AddEventScreen(),
      ),
      GoRoute(
        path: '/edit_event',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return EditEventScreen(event: event);
        },
      ),
      GoRoute(
        path: '/view_participants',
        builder: (context, state) {
          final event = state.extra as EventModel;
          return ViewParticipantsScreen(event: event);
        },
      ),
      GoRoute(
        path: '/scroll_mode',
        builder: (context, state) => const ScrollModeScreen(),
      ),
    ],
  );
});
