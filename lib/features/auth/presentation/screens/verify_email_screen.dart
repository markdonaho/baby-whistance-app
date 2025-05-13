import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter for navigation
import 'package:firebase_auth/firebase_auth.dart'; // Import for User type
import 'package:baby_whistance_app/config/router/app_router.dart'; // Import for appRouterProvider
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:baby_whistance_app/features/auth/application/auth_controller.dart'; // Import AuthController
// TODO: Import AuthRepository for type safety when using its methods
// import 'package:baby_whistance_app/features/auth/domain/repositories/auth_repository.dart';
// TODO: Import the actual auth_providers.dart file
// import 'package:baby_whistance_app/features/auth/application/auth_providers.dart';

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('[VerifyEmailScreen] build() CALLED');
    
    // Listen to the auth controller for potential errors to show in a SnackBar
    ref.listen<AsyncValue<User?>>(authControllerProvider, (_, state) {
      print('[VerifyEmailScreen] authControllerProvider LISTENER triggered. State: ${state.toString()}');
      if (state is AsyncError && state.error != null) {
        print('[VerifyEmailScreen] Listener caught error: ${state.error.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${state.error.toString()}')),
        );
      }
    });
    print('[VerifyEmailScreen] build() - authControllerProvider listener SET UP');

    final authUser = ref.watch(authControllerProvider.select((s) => s.value));
    print('[VerifyEmailScreen] build() - authControllerProvider.select((s) => s.value) WATCHED. User: ${authUser?.uid}, Verified: ${authUser?.emailVerified}');

    return AppScaffold(
      title: 'Verify Your Email',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'A verification email has been sent to your email address. Please check your inbox (and spam folder!) and click the link to verify your email.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  print('[VerifyEmailScreen] Resend Verification Email button PRESSED');
                  await ref.read(authControllerProvider.notifier).sendEmailVerification();
                  print('[VerifyEmailScreen] sendEmailVerification call COMPLETED');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email resent!')),
                    );
                  }
                },
                child: const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  print('[VerifyEmailScreen] Refresh Status button PRESSED');
                  final isVerified = await ref.read(authControllerProvider.notifier).checkIsEmailVerified();
                  print('[VerifyEmailScreen] checkIsEmailVerified call COMPLETED. Result: $isVerified');
                  if (context.mounted) {
                    if (isVerified) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email is verified! Attempting to redirect...')),
                      );
                      // Explicitly navigate to home if verified
                      if (context.mounted) { // Double-check mounted before async gap
                        context.goNamed(AppRoute.home.name);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email not verified yet. Please check again.')),
                      );
                    }
                  }
                },
                child: const Text('Refresh Status'), // Kept simplified text
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  print('[VerifyEmailScreen] Back to Login / Sign Out button PRESSED');
                  ref.read(authControllerProvider.notifier).signOut();
                  print('[VerifyEmailScreen] signOut call COMPLETED');
                  // Router will redirect to /login after sign out
                },
                child: const Text('Back to Login / Sign Out'),
              )
            ],
          ),
        ),
      ),
    );
  }
} 