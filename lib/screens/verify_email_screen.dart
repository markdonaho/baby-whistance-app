import 'package:baby_whistance_app/config/router/app_router.dart';
import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // aliased
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isResendingEmail = false;
  bool _isCheckingStatus = false;
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    // Setup listener for auth errors, potentially to show a SnackBar
    ref.listen<AsyncValue<firebase_auth.User?>>(authControllerProvider, (previous, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          if (mounted) { // Check if widget is still in the tree
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${error.toString()}")),
            );
          }
        },
      );
    });

    final authUser = ref.watch(authControllerProvider).value;

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
                  onPressed: _isResendingEmail || _isCheckingStatus || _isSigningOut ? null : () async {
                    setState(() => _isResendingEmail = true);
                    try {
                      await ref.read(authControllerProvider.notifier).sendEmailVerification();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification email resent!')),
                      );
                    } on firebase_auth.FirebaseAuthException catch (e) {
                      if (!mounted) return;
                      String errorMessage = 'Failed to resend email. Please try again.';
                      if (e.code == 'too-many-requests') {
                        errorMessage = 'Too many requests to resend verification email. Please wait a while before trying again.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage)),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to resend email: ${e.toString()}')),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isResendingEmail = false);
                      }
                    }
                  },
                  child: _isResendingEmail 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Resend Verification Email'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isResendingEmail || _isCheckingStatus || _isSigningOut ? null : () async {
                    setState(() => _isCheckingStatus = true);
                    try {
                      final isVerified = await ref.read(authControllerProvider.notifier).checkIsEmailVerified();
                      // GoRouter will handle navigation if email is verified due to auth state change
                      if (!isVerified && mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please verify your email first.')),
                        );
                      }
                    } catch (e) {
                       if (!mounted) return;
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to check verification status: ${e.toString()}')),
                      );
                    } finally {
                      if (mounted) {
                        setState(() => _isCheckingStatus = false);
                      }
                    }
                  },
                  child: _isCheckingStatus
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('I\'ve Verified / Refresh Status'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _isResendingEmail || _isCheckingStatus || _isSigningOut ? null : () async {
                    setState(() => _isSigningOut = true);
                    try {
                      await ref.read(authControllerProvider.notifier).signOut();
                      // GoRouter will navigate to login screen on sign out
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: ${e.toString()}')),
                      );
                    } finally {
                      // No need to set _isSigningOut = false if navigating away, 
                      // but good practice if there was a path where it didn't navigate.
                      if (mounted) {
                         setState(() => _isSigningOut = false); 
                      }
                    }
                  },
                  child: _isSigningOut
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Back to Login / Sign Out'),
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