import 'package:baby_whistance_app/config/router/app_router.dart';
import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController(); // Added display name controller
  bool _isLoading = false;

  // For showing SnackBars
  late final ScaffoldMessengerState _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    // Initialize _scaffoldMessenger in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldMessenger = ScaffoldMessenger.of(context);
    });
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final AuthController authController = ref.read(authControllerProvider.notifier);
        await authController.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _displayNameController.text.trim(), // Pass display name
        );
        // The redirect logic in GoRouter will handle navigation based on auth state.
        // No explicit navigation needed here if GoRouter is set up for it.

      } catch (e, stackTrace) {
        // Error should be handled by the listener below or via state.when
        // but good to have a catch-all here if something unexpected happens.
      }
    } else {
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose(); // Dispose display name controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the authControllerProvider for errors or state changes
    ref.listen<AsyncValue<User?>>(authControllerProvider, (previous, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          String errorMessage = "An unexpected error occurred during sign up. Please try again.";
          if (error is FirebaseAuthException) {
            if (error.code == 'weak-password') {
              errorMessage = 'The password provided is too weak.';
            } else if (error.code == 'email-already-in-use') {
              errorMessage = 'An account already exists for that email.';
            } else if (error.code == 'invalid-email') {
              errorMessage = 'The email address is not valid.';
            } else if (error.code == 'operation-not-allowed') {
              errorMessage = 'Sign up with email and password is not enabled.'; // Should be enabled in Firebase console
            }
             // Use _scaffoldMessenger if initialized, otherwise use ScaffoldMessenger.of(context)
            // It seems _scaffoldMessenger might not be initialized if an error occurs very early.
            // Using ScaffoldMessenger.of(context) directly is safer within listeners if context is available.
            if (mounted) { // Ensure widget is still in the tree
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage)),
              );
            }
          } else {
            // Handle non-FirebaseAuth errors or show a generic message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error.toString())),
              );
            }
          }
        },
      );
    });

    final authState = ref.watch(authControllerProvider);

    final Widget body = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: 'Display Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your display name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) { // Simple email validation
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Password must contain an uppercase letter';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Password must contain a lowercase letter';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Password must contain a number';
                      }
                      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                        return 'Password must contain a special character';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _signUp,
                      child: const Text('Sign Up'),
                    ),
                  TextButton(
                    onPressed: () => context.goNamed(AppRoute.login.name),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

    return AppScaffold(
      title: 'Sign Up',
      body: body,
      showBottomNavBar: false,
    );
  }
} 