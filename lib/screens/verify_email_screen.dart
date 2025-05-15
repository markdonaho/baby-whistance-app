import 'package:baby_whistance_app/config/router/app_router.dart';
import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // aliased
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Setup listener for auth errors, potentially to show a SnackBar
    ref.listen<AsyncValue<firebase_auth.User?>>(authControllerProvider, (previous, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${error.toString()}")),
          );
        },
      );
    });

    final authUserAsyncValue = ref.watch(authControllerProvider.select((s) => s.value));
    final firebase_auth.User? authUser = authUserAsyncValue;

    final Widget body = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'A verification email has been sent to ${authUser?.email ?? 'your email'}.\nPlease check your inbox and click the link to verify your account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(authControllerProvider.notifier).sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification email resent!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to resend email: ${e.toString()}')),
                      );
                    }
                  },
                  child: const Text('Resend Verification Email'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final isVerified = await ref.read(authControllerProvider.notifier).checkIsEmailVerified();
                    // GoRouter will handle navigation if email is verified due to auth state change
                    if (!isVerified && context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please verify your email first.')),
                      );
                    }
                  },
                  child: const Text('I\'ve Verified / Refresh Status'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    // GoRouter will navigate to login screen on sign out
                  },
                  child: const Text('Back to Login / Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );

    return AppScaffold(
      title: 'Verify Your Email',
      body: body,
      showBottomNavBar: false,
    );
  }
} 