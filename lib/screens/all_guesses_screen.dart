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
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:baby_whistance_app/features/app_status/app_status_service.dart'; // Import AppStatusService

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

  // Helper to format weight from pounds and ounces map
  String _formatActualWeight(Map<String, dynamic>? details) {
    if (details == null) return "N/A";
    final int pounds = details['weightPounds'] as int? ?? 0;
    final int ounces = details['weightOunces'] as int? ?? 0;
    return "$pounds lbs $ounces oz";
  }

  Widget _buildActualDetailsCard(BuildContext context, Map<String, dynamic> actualDetails) {
    String formattedTimeOfBirth = actualDetails['timeOfBirth'] as String? ?? 'N/A';
    if (formattedTimeOfBirth != 'N/A') {
      try {
        final hour = int.parse(formattedTimeOfBirth.split(':')[0]);
        final minute = int.parse(formattedTimeOfBirth.split(':')[1]);
        final dateTime = DateTime(2000, 1, 1, hour, minute); // Dummy date
        formattedTimeOfBirth = DateFormat('h:mm a').format(dateTime);
      } catch (e) {
        print('Error formatting actual time of birth: ${actualDetails['timeOfBirth']} - $e');
        formattedTimeOfBirth = actualDetails['timeOfBirth'] as String? ?? 'N/A'; // Revert to original if parsing fails
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'He\'s Here! Announcing Baby Whistance!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Actual details - using helper from GuessSubmissionEditScreen for weight display consistency
            // Text('Born on: ${DateFormat('MMMM d, yyyy').format(fixedBirthDate)}', style: Theme.of(context).textTheme.titleMedium), // Assuming fixedBirthDate is the actual date for now
            Text('Time of Birth: $formattedTimeOfBirth', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
            Text('Weight: ${_formatActualWeight(actualDetails)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
            Text('Length: ${actualDetails['lengthInches'] ?? 'N/A'} inches', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
            Text('Hair Color: ${actualDetails['hairColor'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
            Text('Eye Color: ${actualDetails['eyeColor'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGuessesAsyncValue = ref.watch(allGuessesStreamProvider);
    final appStatusAsync = ref.watch(currentAppStatusProvider);

    // Determine if scores should be shown (guessing revealed and actual details present)
    final showScores = appStatusAsync.maybeWhen(
      data: (status) => status.guessingStatus == GuessingStatus.revealed && status.actualBabyDetails != null,
      orElse: () => false,
    );

    return AppScaffold(
      title: 'All Guesses',
      body: appStatusAsync.when(
        data: (appStatus) {
          final bool isRevealed = appStatus.guessingStatus == GuessingStatus.revealed;
          final actualDetails = appStatus.actualBabyDetails;

          return Column(
            children: [
              if (isRevealed && actualDetails != null)
                _buildActualDetailsCard(context, actualDetails),
              Expanded(
                child: allGuessesAsyncValue.when(
                  data: (guesses) {
                    if (guesses.isEmpty) {
                      return const Center(child: Text('No guesses submitted yet from anyone!'));
                    }
                    return ListView.builder(
                      itemCount: guesses.length,
                      itemBuilder: (context, index) {
                        final guess = guesses[index];
                        return GuessListItem(guess: guess, showScores: showScores);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error fetching all guesses: ${err.toString()}')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()), // Loading for app status
        error: (err, stack) => Center(child: Text('Error loading app status: ${err.toString()}')), // Error for app status
      ),
      showBottomNavBar: true,
      floatingActionButton: appStatusAsync.when(
        data: (status) {
          if (status.guessingStatus == GuessingStatus.open) {
            return FloatingActionButton.extended(
              onPressed: () {
                context.goNamed(AppRoute.guessForm.name, queryParameters: {'edit': 'true'});
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('My Guess'),
              tooltip: 'Submit or Edit Your Guess',
            );
          }
          return null; // No FAB if guessing is not open
        },
        loading: () => const SizedBox.shrink(), // Or a small loading indicator
        error: (err, stack) => const SizedBox.shrink(), // No FAB on error
      ),
    );
  }
}

class GuessListItem extends ConsumerStatefulWidget {
  final Guess guess;
  final bool showScores;
  const GuessListItem({super.key, required this.guess, required this.showScores});

  @override
  ConsumerState<GuessListItem> createState() => _GuessListItemState();
}

class _GuessListItemState extends ConsumerState<GuessListItem> {
  bool _isExpanded = false;

  List<Widget> _buildScoreBreakdownDetails(Map<String, dynamic> breakdown, BuildContext context) {
    final List<Widget> details = [];
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    breakdown.forEach((key, value) {
      String displayKey = key.replaceAll('_', ' ').split(' ').map((str) => str[0].toUpperCase() + str.substring(1)).join(' ');
      if (value is Map && value.containsKey('points') && value.containsKey('detail')) {
        details.add(Text('$displayKey: ${value["points"]} pts (${value["detail"]})', style: textStyle));
      } else if (value is num) {
        details.add(Text('$displayKey: $value pts', style: textStyle));
      } else {
        details.add(Text('$displayKey: $value', style: textStyle));
      }
    });
    if (details.isEmpty) {
      details.add(Text('No breakdown available.', style: textStyle?.copyWith(fontStyle: FontStyle.italic)));
    }
    return details;
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(userProvider(widget.guess.userId));

    String formattedTimeGuess = widget.guess.timeGuess;
    try {
      final hour = int.parse(widget.guess.timeGuess.split(':')[0]);
      final minute = int.parse(widget.guess.timeGuess.split(':')[1]);
      final dateTime = DateTime(2000, 1, 1, hour, minute);
      formattedTimeGuess = DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      print('Error formatting time guess: ${widget.guess.timeGuess} - $e');
    }

    final cardContent = Column(
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
        Text('Target Date: ${DateFormat('MMMM d, yyyy').format(widget.guess.dateGuess.toDate())}'),
        Text('Time: $formattedTimeGuess'),
        Text('Weight: ${formatWeight(widget.guess.weightGuess)}'),
        Text('Length: ${widget.guess.lengthGuess} inches'),
        Text('Hair Color: ${widget.guess.hairColorGuess}'),
        Text('Eye Color: ${widget.guess.eyeColorGuess}'),
        Text('Looks Like: ${widget.guess.looksLikeGuess}'),
        if (widget.guess.brycenReactionGuess != null && widget.guess.brycenReactionGuess!.isNotEmpty)
          Text('Brycen\'s Reaction: ${widget.guess.brycenReactionGuess}'),
        
        if (widget.showScores && widget.guess.totalScore != null) ...[
          const SizedBox(height: 8),
          Text(
            'Total Score: ${widget.guess.totalScore}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ],
        const SizedBox(height: 8),
        Text('Submitted: ${DateFormat('MMM d, yyyy HH:mm').format(widget.guess.submittedAt.toDate())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );

    if (widget.showScores && widget.guess.scoreBreakdown != null && widget.guess.scoreBreakdown!.isNotEmpty) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: ExpansionTile(
          key: PageStorageKey(widget.guess.id),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: cardContent,
          ),
          onExpansionChanged: (bool expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          initiallyExpanded: _isExpanded,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0, top:0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Score Breakdown:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ..._buildScoreBreakdownDetails(widget.guess.scoreBreakdown!, context),
                ],
              ),
            )
          ],
        ),
      );
    } else {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: cardContent,
        ),
      );
    }
  }
} 