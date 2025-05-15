import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:baby_whistance_app/config/router/app_router.dart'; // For route names

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final User? user = await ref.read(authControllerProvider.notifier).signInWithEmailAndPassword(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        

        if (!mounted) {
             return;
        }

        if (user != null && user.emailVerified == true) {
          // Navigation is handled by GoRouter's redirect logic based on AuthController state
          // context.goNamed(AppRoute.guessForm.name); // No longer needed here if GoRouter handles it
        } else if (user != null && user.emailVerified == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please verify your email. Check your inbox or resend verification from the profile page if needed.')),
          );
        } else if (user == null) {
           // This case might be hit if signInWithEmailAndPassword returns null without an exception
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please check your credentials and try again.')),
          );
        }

      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String errorMessage = 'An unexpected error occurred. Please try again.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided for that user.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'This user account has been disabled.';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many login attempts. Please try again later.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred: ${e.toString()}")),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        } else {
        }
      }
    } else {
    }
  }

  void _showForgotPasswordDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    bool isSendingResetEmail = false; // Local state for dialog's button

    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage the loading state within the dialog
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Enter your email address and we will send you a link to reset your password.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSendingResetEmail ? null : () async {
                    if (emailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your email address.')),
                      );
                      return;
                    }
                    setStateDialog(() {
                      isSendingResetEmail = true;
                    });
                    try {
                      await ref
                          .read(authControllerProvider.notifier)
                          .sendPasswordResetEmail(emailController.text.trim());
                      if (!mounted) return; // Check mounted context before showing SnackBar
                      Navigator.of(context).pop(); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Password reset email sent. Please check your inbox.')),
                      );
                    } on FirebaseAuthException catch (e) {
                      if (!mounted) return; 
                      Navigator.of(context).pop(); // Close dialog
                      String errorMessage = 'Failed to send reset email.';
                      if (e.code == 'invalid-email') {
                        errorMessage = 'The email address is not valid.';
                      } else if (e.code == 'user-not-found') {
                        errorMessage = 'No user found for this email.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage)),
                      );
                    } catch (e) {
                      if (!mounted) return; 
                      Navigator.of(context).pop(); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    } finally {
                       if (mounted) { // Check mounted before calling setStateDialog
                         setStateDialog(() {
                           isSendingResetEmail = false;
                         });
                       }
                    }
                  },
                  child: isSendingResetEmail 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Send Reset Email'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (_, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
        // loading: () { // Handled by _isLoading locally for the button }
      );
    });

    final authStateIsLoading = ref.watch(authControllerProvider.select((s) => s.isLoading));

    final Widget body = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    // Navigate to Sign Up screen
                    // Ensure AppRoute anmes are correctly defined in your router
                    context.goNamed(AppRoute.signup.name);
                  },
                  child: const Text('Create an account'),
                ),
                const SizedBox(height: 8.0), // Space before forgot password
                TextButton(
                  onPressed: () => _showForgotPasswordDialog(context, ref),
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
          ),
        ),
      );

    return AppScaffold(
      title: 'Login',
      body: body,
      showBottomNavBar: false,
    );
  }
} 