import 'package:flutter/material.dart';
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart'; // Assuming AppScaffold is appropriate
// TODO: Import AuthRepository and a way to access it (e.g., Provider/Riverpod)
// import 'package:baby_whistance_app/features/auth/domain/repositories/auth_repository.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart'; // Or your chosen state management

class VerifyEmailScreen extends StatelessWidget { // Or ConsumerWidget if using Riverpod
  const VerifyEmailScreen({super.key});

  // TODO: Access AuthRepository instance here (e.g., via ref.watch for Riverpod)

  @override
  Widget build(BuildContext context) { // Or WidgetRef ref for Riverpod
    // final authRepository = ref.watch(authRepositoryProvider); // Example for Riverpod

    return AppScaffold( // Using AppScaffold for consistency
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
                  // TODO: Implement resend verification email
                  // await authRepository.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email resent!')),
                  );
                },
                child: const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // TODO: Implement check verification status and navigate
                  // final isVerified = await authRepository.isEmailVerified();
                  // if (isVerified) {
                  //   // TODO: Navigate to home or appropriate screen
                  //   // context.go('/home'); // Example with GoRouter
                  // } else {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(content: Text('Email not verified yet. Please check your email or try again.')),
                  //   );
                  // }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Check status functionality to be implemented.')),
                  );
                },
                child: const Text('I've Verified / Refresh Status'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // TODO: Optionally, navigate to login or allow user to go back
                  // context.go('/login'); // Example
                },
                child: const Text('Back to Login (Optional)'),
              )
            ],
          ),
        ),
      ),
    );
  }
} 