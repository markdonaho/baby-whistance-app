import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:baby_whistance_app/features/auth/application/auth_controller.dart';
import 'package:baby_whistance_app/config/router/app_router.dart'; // For route names

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() {
    print('[LoginScreen] createState() CALLED');
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
    print('[LoginScreen] initState() CALLED');
  }

  @override
  void dispose() {
    print('[LoginScreen] dispose() CALLED');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    print('[LoginScreen] _login method CALLED.');

    if (_formKey.currentState!.validate()) {
      print('[LoginScreen] Form validation SUCCEEDED.');
      setState(() {
        _isLoading = true;
      });
      try {
        print('[LoginScreen] Attempting to call signInWithEmailAndPassword...');
        final User? user = await ref.read(authControllerProvider.notifier).signInWithEmailAndPassword(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
        
        print('[LoginScreen] Returned from AuthController.signInWithEmailAndPassword call.');
        print('[LoginScreen] User object in LoginScreen: \${user?.toString()}');
        print('[LoginScreen] User UID in LoginScreen: \${user?.uid}');
        print('[LoginScreen] User Email in LoginScreen: \${user?.email}');
        print('[LoginScreen] Is email verified in LoginScreen (from returned user): \${user?.emailVerified}');

        if (!mounted) {
             print('[LoginScreen] Widget NOT MOUNTED after auth call and before navigation/logic. Returning.');
             return;
        }
        print('[LoginScreen] Widget IS MOUNTED after auth call and before navigation/logic.');

        if (user != null && user.emailVerified == true) {
          print('[LoginScreen] Condition: user != null && user.emailVerified == true. Attempting to navigate to home...');
          context.goNamed(AppRoute.home.name);
          print('[LoginScreen] context.goNamed(AppRoute.home.name) CALLED.');
        } else if (user != null && user.emailVerified == false) {
          print('[LoginScreen] Condition: user != null && user.emailVerified == false (email NOT verified).');
        } else if (user == null) {
          print('[LoginScreen] Condition: user == null (login failed).');
        } else {
          // This case should ideally not be reached if user.emailVerified is a boolean.
          print('[LoginScreen] Condition: Fallthrough. User: \${user?.uid}, EmailVerified: \${user?.emailVerified}');
        }

      } catch (e, stackTrace) {
        print('[LoginScreen] EXCEPTION CAUGHT in _login: \${e.toString()}');
        print('[LoginScreen] StackTrace: \${stackTrace.toString()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("An unexpected error occurred: \${e.toString()}")),
          );
        }
      } finally {
        print('[LoginScreen] Entering _login FINALLY block.');
        if (mounted) {
          print('[LoginScreen] In _login FINALLY block. Widget IS mounted. Setting _isLoading = false.');
          setState(() {
            _isLoading = false;
          });
        } else {
            print('[LoginScreen] In _login FINALLY block. Widget NOT mounted when trying to set _isLoading.');
        }
      }
    } else {
      print('[LoginScreen] Form validation FAILED.');
    }
  }

  void _showForgotPasswordDialog(BuildContext context, WidgetRef ref) {
    print('[LoginScreen] _showForgotPasswordDialog CALLED');
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  try {
                    await ref
                        .read(authControllerProvider.notifier)
                        .sendPasswordResetEmail(emailController.text.trim());
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password reset email sent. Please check your inbox.')),
                    );
                  } catch (e) {
                    Navigator.of(context).pop(); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email address.')),
                  );
                }
              },
              child: const Text('Send Reset Email'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[LoginScreen] build() CALLED');
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (_, state) {
      print('[LoginScreen] authControllerProvider LISTENER triggered. State: ${state.toString()}');
      state.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
        // loading: () { // Handled by _isLoading locally for the button }
      );
    });
    print('[LoginScreen] build() - authControllerProvider listener SET UP');

    final authStateIsLoading = ref.watch(authControllerProvider.select((s) => s.isLoading));
    print('[LoginScreen] build() - authControllerProvider.select((s) => s.isLoading) WATCHED. Value: $authStateIsLoading');

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
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
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: () => _showForgotPasswordDialog(context, ref),
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 