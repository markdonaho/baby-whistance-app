import 'package:baby_whistance_app/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Actual screen imports
import 'package:baby_whistance_app/features/auth/presentation/screens/login_screen.dart';
import 'package:baby_whistance_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:baby_whistance_app/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:baby_whistance_app/features/home/presentation/screens/home_screen.dart';
import 'package:baby_whistance_app/features/upload/presentation/screens/upload_photo_screen.dart';
import 'package:baby_whistance_app/features/admin/presentation/screens/admin_screen.dart';
import 'package:baby_whistance_app/features/profile/presentation/screens/profile_screen.dart';

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
      print('[GoRouter] REDIRECT CALLED. Current location: ${state.matchedLocation}, Name: ${state.name}');

      final authControllerState = ref.read(authControllerProvider);
      print('[GoRouter] AuthController state: ${authControllerState.toString()}');

      final loggedIn = authControllerState.when(
        data: (user) {
          print('[GoRouter] Auth state is DATA. User: ${user?.uid}, EmailVerified: ${user?.emailVerified}');
          return user != null;
        },
        loading: () {
          print('[GoRouter] Auth state is LOADING.');
          return false;
        },
        error: (err, stack) {
          print('[GoRouter] Auth state is ERROR: $err');
          return false;
        },
      );

      final isVerified = authControllerState.when(
        data: (user) => user?.emailVerified ?? false,
        loading: () => false,
        error: (_, __) => false,
      );
      print('[GoRouter] Calculated loggedIn: $loggedIn, isVerified: $isVerified');

      final currentRouteName = state.name;
      final currentLocationPath = state.matchedLocation;

      final goingToLogin = currentLocationPath == '/login' || currentRouteName == AppRoute.login.name;
      final goingToSignup = currentLocationPath == '/signup' || currentRouteName == AppRoute.signup.name;
      final goingToVerifyEmail = currentLocationPath == '/verify-email' || currentRouteName == AppRoute.verifyEmail.name;

      print('[GoRouter] Path checks: currentLocationPath: $currentLocationPath, currentRouteName: $currentRouteName');
      print('[GoRouter] goingToLogin: $goingToLogin, goingToSignup: $goingToSignup, goingToVerifyEmail: $goingToVerifyEmail');

      const publicRouteNames = {
        // AppRoute.login.name,
        // AppRoute.signup.name,
      };

      final publicPaths = [
        '/login',
        '/signup',
      ];

      final authRequiredPaths = [
        '/verify-email',
      ];

      final emailVerifiedPaths = [
        '/home',
        '/profile',
        '/upload-photo',
        '/admin',
      ];

      final isPublicRoute = publicPaths.contains(state.matchedLocation);
      final isEmailVerifiedRoute = emailVerifiedPaths.contains(state.matchedLocation);

      print('[GoRouter] Routing checks: isPublicRoute: $isPublicRoute, isEmailVerifiedRoute: $isEmailVerifiedRoute, goingToLogin: $goingToLogin, goingToSignup: $goingToSignup, goingToVerifyEmail: $goingToVerifyEmail');

      if (authControllerState is AsyncLoading) {
        print('[GoRouter] Auth state is AsyncLoading, redirect returns null (no change).');
        return null;
      }

      if (!loggedIn) {
        print('[GoRouter] User NOT loggedIn.');
        if (!isPublicRoute) {
          print('[GoRouter] User NOT loggedIn and NOT on public route. Redirecting to /login.');
          return '/login';
        }
        print('[GoRouter] User NOT loggedIn but IS on public route. No redirect.');
        return null;
      }

      print('[GoRouter] User IS loggedIn.');
      if (!isVerified) {
        print('[GoRouter] User loggedIn but NOT verified.');
        if (isEmailVerifiedRoute) {
          print('[GoRouter] User loggedIn, NOT verified, but trying to access verified-only route. Redirecting to /verify-email.');
          return '/verify-email';
        }
        if (goingToLogin || goingToSignup || goingToVerifyEmail) {
          print('[GoRouter] User loggedIn, NOT verified, but going to login/signup/verify. No redirect from here, allow.');
          return null;
        }
        print('[GoRouter] User loggedIn, NOT verified, and not on a special page. Default redirect to /verify-email.');
        return '/verify-email';
      }

      print('[GoRouter] User IS loggedIn AND IS verified.');
      if (goingToLogin || goingToSignup || goingToVerifyEmail) {
        print('[GoRouter] User loggedIn AND verified, but going to login/signup/verify. Redirecting to /home.');
        return '/home';
      }

      print('[GoRouter] User loggedIn AND verified. No specific redirect condition met. Returning null (allow navigation).');
      return null;
    },
  );
});