import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart'; // Provides AppUser and firestoreProvider (indirectly via other providers if not directly)
// import 'package:baby_whistance_app/features/auth/domain/app_user_model.dart'; // REMOVE this incorrect import
import 'package:baby_whistance_app/features/guesses/application/guess_controller.dart';
import 'package:baby_whistance_app/features/guesses/domain/guess_model.dart';
import 'package:baby_whistance_app/screens/guess_submission_edit_screen.dart'; // New import for formatWeight
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For DateFormat
import 'package:go_router/go_router.dart'; // Added for navigation
import 'package:baby_whistance_app/config/router/app_router.dart'; // Added for AppRoute enum

// Placeholder provider for fetching a user by ID.
// You might already have a more robust way to do this, e.g., a UserRepository or similar.
final userProvider = FutureProvider.family<AppUser?, String>((ref, userId) async {
  // This is a simplified example. Replace with your actual user fetching logic.
  // It assumes appUserProvider gives the current user, which is not what we want here.
  // We need a way to fetch *any* user by their ID.
  // For now, it will try to get it from a Firestore 'users' collection.
  final firestore = ref.watch(firebaseFirestoreInstanceProvider); // Corrected to use firebaseFirestoreInstanceProvider
  final doc = await firestore.collection('users').doc(userId).get();
  if (doc.exists) {
    return AppUser.fromFirestore(doc, null); // Pass the snapshot directly
  }
  return null;
});


class AllGuessesScreen extends ConsumerWidget {
  const AllGuessesScreen({super.key});

  static const routeName = '/all-guesses';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGuessesAsyncValue = ref.watch(allGuessesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Guesses'),
        // Potentially add a button to navigate to submit/edit guess screen
      ),
      body: allGuessesAsyncValue.when(
        data: (guesses) {
          if (guesses.isEmpty) {
            return const Center(child: Text('No guesses submitted yet from anyone!'));
          }
          return ListView.builder(
            itemCount: guesses.length,
            itemBuilder: (context, index) {
              final guess = guesses[index];
              return GuessListItem(guess: guess);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error fetching all guesses: ${err.toString()}')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.goNamed(AppRoute.guessForm.name, queryParameters: {'edit': 'true'});
        },
        icon: const Icon(Icons.edit_note),
        label: const Text('My Guess'),
        tooltip: 'Submit or Edit Your Guess',
      ),
    );
  }
}

class GuessListItem extends ConsumerWidget {
  final Guess guess;
  const GuessListItem({super.key, required this.guess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch the user's display name
    final userAsyncValue = ref.watch(userProvider(guess.userId));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsyncValue.when(
              data: (appUser) => Text(
                appUser?.displayName ?? 'Unknown User',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              loading: () => const Text('Loading user...', style: TextStyle(fontStyle: FontStyle.italic)),
              error: (err, stack) => Text('Error loading user: ${err.toString()}', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 8),
            Text('Target Date: ${DateFormat('MMMM d, yyyy').format(guess.dateGuess.toDate())}'),
            Text('Time: ${guess.timeGuess}'),
            Text('Weight: ${formatWeight(guess.weightGuess)}'), // Using formatWeight from home_screen
            Text('Length: ${guess.lengthGuess} inches'),
            Text('Hair Color: ${guess.hairColorGuess}'),
            Text('Eye Color: ${guess.eyeColorGuess}'),
            Text('Looks Like: ${guess.looksLikeGuess}'),
            if (guess.brycenReactionGuess != null && guess.brycenReactionGuess!.isNotEmpty)
              Text('Brycen\'s Reaction: ${guess.brycenReactionGuess}'),
            const SizedBox(height: 8),
            Text('Submitted: ${DateFormat('MMM d, yyyy HH:mm').format(guess.submittedAt.toDate())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
} 