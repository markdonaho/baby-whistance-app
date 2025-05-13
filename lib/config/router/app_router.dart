import 'package:baby_whistance_app/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Actual screen imports
import 'package:baby_whistance_app/features/auth/presentation/screens/login_screen.dart';
import 'package:baby_whistance_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:baby_whistance_app/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:baby_whistance_app/features/home/presentation/screens/home_screen.dart';
import 'package:baby_whistance_app/features/upload/presentation/screens/upload_photo_screen.dart';
import 'package:baby_whistance_app/features/admin/presentation/screens/admin_screen.dart';
import 'package:baby_whistance_app/features/profile/presentation/screens/profile_screen.dart';

// Provider for the GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/upload-photo',
        builder: (context, state) => const UploadPhotoScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = authState.when(
        data: (user) => user != null,
        loading: () => false,
        error: (_, __) => false,
      );
      final isVerified = authState.when(
        data: (user) => user?.emailVerified ?? false,
        loading: () => false,
        error: (_, __) => false,
      );

      final goingToLogin = state.matchedLocation == '/login';
      final goingToSignup = state.matchedLocation == '/signup';
      final goingToVerifyEmail = state.matchedLocation == '/verify-email';

      const publicPaths = [
        '/login',
        '/signup',
      ];

      const authRequiredPaths = [
        '/verify-email'
      ];

      const emailVerifiedPaths = [
        '/home',
        '/profile',
        '/upload-photo',
        '/admin'
      ];

      final isPublicRoute = publicPaths.contains(state.matchedLocation);
      final isAuthRequiredRoute = authRequiredPaths.contains(state.matchedLocation);
      final isEmailVerifiedRoute = emailVerifiedPaths.contains(state.matchedLocation);

      if (authState is AsyncLoading) {
        return null;
      }

      if (!loggedIn) {
        if (!isPublicRoute) {
          return '/login';
        }
        return null;
      }

      if (!isVerified) {
        if (isEmailVerifiedRoute) {
          return '/verify-email';
        }
        if (goingToVerifyEmail || isAuthRequiredRoute || isPublicRoute) {
          return null;
        }
        return '/verify-email';
      }

      if (goingToLogin || goingToSignup) {
        return '/home';
      }

      return null;
    },
  );
});