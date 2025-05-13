import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Actual screen imports
import 'package:baby_whistance_app/features/auth/presentation/screens/login_screen.dart';
import 'package:baby_whistance_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:baby_whistance_app/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:baby_whistance_app/features/home/presentation/screens/home_screen.dart';
import 'package:baby_whistance_app/features/upload/presentation/screens/upload_photo_screen.dart';
import 'package:baby_whistance_app/features/admin/presentation/screens/admin_screen.dart';
import 'package:baby_whistance_app/features/profile/presentation/screens/profile_screen.dart';

// Simple placeholder widget to use until actual screens are created
// class PlaceholderScreen extends StatelessWidget { // No longer needed for route builders
//   final String title;
//   const PlaceholderScreen({super.key, required this.title});
// 
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: Center(child: Text('Screen: \$title')),
//     );
//   }
// }

final GoRouter appRouter = GoRouter(
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
  // errorBuilder: (context, state) => ErrorScreen(error: state.error), // Optional: For handling routing errors
); 