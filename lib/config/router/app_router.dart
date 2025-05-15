import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Actual screen imports
import 'package:baby_whistance_app/screens/login_screen.dart';
import 'package:baby_whistance_app/screens/signup_screen.dart';
import 'package:baby_whistance_app/screens/verify_email_screen.dart';
import 'package:baby_whistance_app/screens/home_screen.dart';
import 'package:baby_whistance_app/screens/upload_photo_screen.dart';
import 'package:baby_whistance_app/screens/admin_screen.dart';
import 'package:baby_whistance_app/screens/profile_screen.dart';

// Enum for route names to ensure type safety and centralize route management
enum AppRoute {
  login,
  signup,
  verifyEmail,
  home,
  uploadPhoto,
  admin,
  profile,
}

// Provider for the GoRouter instance
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true, // This provides verbose GoRouter logging. Set to false for production.
    routes: [
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: AppRoute.signup.name,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: AppRoute.verifyEmail.name,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/home',
        name: AppRoute.home.name,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/upload-photo',
        name: AppRoute.uploadPhoto.name,
        builder: (context, state) => const UploadPhotoScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: AppRoute.admin.name,
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: AppRoute.profile.name,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authControllerState = ref.read(authControllerProvider);

      final loggedIn = authControllerState.when(
        data: (user) => user != null,
        loading: () => false, // Treat loading as not loggedIn for redirect purposes
        error: (err, stack) => false, // Treat error as not loggedIn
      );

      final isVerified = authControllerState.when(
        data: (user) => user?.emailVerified ?? false,
        loading: () => false,
        error: (_, __) => false,
      );

      final currentLocationPath = state.matchedLocation;
      final goingToLogin = currentLocationPath == '/login';
      final goingToSignup = currentLocationPath == '/signup';
      final goingToVerifyEmail = currentLocationPath == '/verify-email';

      final publicPaths = ['/login', '/signup'];
      final emailVerifiedPaths = ['/home', '/profile', '/upload-photo', '/admin'];

      final isPublicRoute = publicPaths.contains(currentLocationPath);
      final isEmailVerifiedRoute = emailVerifiedPaths.contains(currentLocationPath);

      if (authControllerState is AsyncLoading) {
        return null; // Do not redirect while auth state is loading
      }

      if (!loggedIn) {
        if (!isPublicRoute) {
          return '/login'; // Not loggedIn and not on a public route, redirect to login
        }
        return null; // Not loggedIn but on a public route, allow
      }

      // User is loggedIn
      if (!isVerified) {
        if (isEmailVerifiedRoute) {
          return '/verify-email'; // LoggedIn, not verified, trying to access verified-only route
        }
        if (goingToLogin || goingToSignup) {
          return '/verify-email'; // LoggedIn, not verified, but on login/signup, redirect to verify
        }
        if (goingToVerifyEmail) {
          return null; // LoggedIn, not verified, but already on verify page, allow
        }
        return '/verify-email'; // Default for loggedIn but not verified
      }

      // User is loggedIn AND verified
      if (goingToLogin || goingToSignup || goingToVerifyEmail) {
        return '/home'; // LoggedIn and verified, but on auth pages, redirect to home
      }

      return null; // All other cases, allow navigation
    },
  );
});