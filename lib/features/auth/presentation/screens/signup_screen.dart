import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:go_router/go_router.dart';
import 'package:baby_whistance_app/features/auth/application/auth_controller.dart'; // Import AuthController
import 'package:baby_whistance_app/config/router/app_router.dart'; // For route names
// No longer directly using FirebaseAuthRepository or AppScaffold if it was specific to old setup

class SignupScreen extends ConsumerStatefulWidget { // Extend ConsumerStatefulWidget
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() {
    print('[SignupScreen] createState() CALLED');
    return _SignupScreenState();
  }
}

class _SignupScreenState extends ConsumerState<SignupScreen> { // Extend ConsumerState
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController(); // Controller for display name
  // bool _isLoading = false; // isLoading will be handled by AsyncValue from controller
  // String? _errorMessage; // error messages will be handled by AsyncValue from controller

  @override
  void initState() {
    super.initState();
    print('[SignupScreen] initState() CALLED');
  }

  Future<void> _signUp() async {
    print('[SignupScreen] _signUp CALLED.');
    if (_formKey.currentState!.validate()) {
      print('[SignupScreen] Form is valid.');
      // No local isLoading or errorMessage state needed when using AsyncNotifier
      try {
        print('[SignupScreen] Calling authController.signUpWithEmailAndPassword...');
        await ref.read(authControllerProvider.notifier).signUpWithEmailAndPassword(
              _emailController.text.trim(),
              _passwordController.text.trim(),
              _displayNameController.text.trim(), // Pass display name
            );
        print('[SignupScreen] authController.signUpWithEmailAndPassword COMPLETED.');
      } catch (e, stackTrace) {
        print('[SignupScreen] ERROR during signUpWithEmailAndPassword: $e');
        print('[SignupScreen] StackTrace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signup failed: ${e.toString()}')),
          );
        }
        return; // Don't proceed if signup failed
      }
      // Navigation to /verify-email or other state handling will be managed
      // by the router listening to authStateChangesProvider or by the controller state itself.
      // We might still want a local check here if the controller doesn't throw an error that stops execution.

      if (!mounted) {
        print('[SignupScreen] Widget NOT MOUNTED after signup call. Returning.');
        return; 
      }
      print('[SignupScreen] Widget IS MOUNTED after signup call.');
      
      final authState = ref.read(authControllerProvider);
      print('[SignupScreen] Current authState before navigation: User: ${authState.value?.uid}, Verified: ${authState.value?.emailVerified}, HasError: ${authState.hasError}, IsLoading: ${authState.isLoading}');

      if (!authState.hasError) {
         print('[SignupScreen] AuthState has NO error. Navigating to verifyEmail...');
         context.goNamed(AppRoute.verifyEmail.name);
         print('[SignupScreen] context.goNamed(AppRoute.verifyEmail.name) CALLED.');
      } else {
         print('[SignupScreen] AuthState HAS error. Error: ${authState.error}. Not navigating explicitly from signup screen.');
         // Potentially show error from authState if not already handled by listener
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Signup issue: ${authState.error?.toString() ?? "Unknown error"}')),
            );
          }
      }
    } else {
      print('[SignupScreen] Form is INVALID.');
    }
  }

  @override
  void dispose() {
    print('[SignupScreen] dispose() CALLED');
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose(); // Dispose display name controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[SignupScreen] build() CALLED');
    
    // Listen to the authControllerProvider for state changes (loading, error, data)
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (_, state) {
      print('[SignupScreen] authControllerProvider LISTENER triggered. State: ${state.toString()}');
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
    print('[SignupScreen] build() - authControllerProvider WATCHED. State: ${authState.toString()}');

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