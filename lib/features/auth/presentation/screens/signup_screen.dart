import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:go_router/go_router.dart';
import 'package:baby_whistance_app/features/auth/application/auth_controller.dart'; // Import AuthController
import 'package:baby_whistance_app/config/router/app_router.dart'; // For route names
// No longer directly using FirebaseAuthRepository or AppScaffold if it was specific to old setup

class SignupScreen extends ConsumerStatefulWidget { // Extend ConsumerStatefulWidget
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> { // Extend ConsumerState
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController(); // Controller for display name
  // bool _isLoading = false; // isLoading will be handled by AsyncValue from controller
  // String? _errorMessage; // error messages will be handled by AsyncValue from controller

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      // No local isLoading or errorMessage state needed when using AsyncNotifier
      await ref.read(authControllerProvider.notifier).signUpWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _displayNameController.text.trim(), // Pass display name
          );
      // Navigation to /verify-email or other state handling will be managed
      // by the router listening to authStateChangesProvider or by the controller state itself.
      // We might still want a local check here if the controller doesn't throw an error that stops execution.

      if (!mounted) return; // Check if widget is still mounted before using ref
      final authState = ref.read(authControllerProvider);
      if (!authState.hasError) {
         // Consider navigating only if signup didn't immediately result in an error state
         // and the user object is available (though email might not be verified yet)
         // The router should handle redirection to /verify-email based on auth state.
         // If not automatically redirecting, explicitly navigate:
         // context.goNamed(AppRoute.verifyEmail.name); 
      } 
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
    // Listen to the authControllerProvider for state changes (loading, error, data)
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (_, state) {
      state.whenOrNull(
        error: (error, stackTrace) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          }
        },
        // data: (data) { // Success is handled by router redirects or local checks in _signUp }
        // loading: () { // Loading indicator is handled below }
      );
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold( // Using standard Scaffold
      appBar: AppBar(title: const Text('Sign Up')),
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
                  'Create your Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                TextFormField(
                  controller: _displayNameController, // Display Name Field
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
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
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                authState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: const Text('Sign Up'),
                      ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    context.goNamed(AppRoute.login.name); // Navigate to Login screen
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 