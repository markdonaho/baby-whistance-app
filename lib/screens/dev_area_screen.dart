import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:baby_whistance_app/features/feedback/domain/feedback_model.dart';
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Added for date formatting

// Provider for submitting feedback
final feedbackServiceProvider = Provider((ref) {
  final firestore = ref.watch(firebaseFirestoreInstanceProvider);
  return FeedbackService(firestore);
});

class FeedbackService {
  final FirebaseFirestore _firestore;
  FeedbackService(this._firestore);

  Future<void> submitFeedback(FeedbackItem feedback) async {
    try {
      await _firestore.collection('feedback').add(feedback.toFirestore());
    } catch (e) {
      print('Error submitting feedback: $e');
      rethrow;
    }
  }

  // Stream for admin/Whistance to view feedback
  Stream<List<FeedbackItem>> getFeedbackStream() {
    return _firestore
        .collection('feedback')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackItem.fromFirestore(doc, null))
            .toList());
  }
}

// Provider for the feedback stream
final feedbackStreamProvider = StreamProvider<List<FeedbackItem>>((ref) {
  final feedbackService = ref.watch(feedbackServiceProvider);
  return feedbackService.getFeedbackStream();
});

class DevAreaScreen extends ConsumerStatefulWidget {
  const DevAreaScreen({super.key});

  @override
  ConsumerState<DevAreaScreen> createState() => _DevAreaScreenState();
}

class _DevAreaScreenState extends ConsumerState<DevAreaScreen> {
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback first.')),
      );
      return;
    }

    final currentUser = ref.read(appUserStreamProvider).asData?.value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit feedback.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final feedbackItem = FeedbackItem(
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'Anonymous',
      userEmail: currentUser.email ?? 'No email',
      timestamp: Timestamp.now(),
      feedbackText: _feedbackController.text,
      // TODO: Add appVersion and platform if available
    );

    try {
      await ref.read(feedbackServiceProvider).submitFeedback(feedbackItem);
      _feedbackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: $e')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ref.watch(appUserStreamProvider).asData?.value; // Get current user to check role
    final bool canViewFeedback = currentUser?.role == AppUserRole.admin || currentUser?.role == AppUserRole.whistance;

    return AppScaffold(
      title: 'Dev Area & Scoring Rules',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Development & Feedback Area',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Welcome to the development area! This screen is currently a placeholder and a space to outline proposed ideas and gather feedback. Your input is valuable!',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24.0),
            Text(
              'Proposed Scoring Rules (Draft)',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            Text(
              '(Reflecting current backend logic from functions/index.js. Note: Date Guess is not currently scored.)',
              style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12.0),
            _buildRuleSection(
              context,
              title: '1. Time, Weight, and Length Guesses (Relative Scoring):',
              points: [
                "Points are awarded based on how close your guess is *relative to all other guesses* for Time, Weight (total ounces), and Length.",
                "The system identifies the top 3 unique closest differences for each category:",
                "  - 1st Closest (or tied for 1st): 30 points",
                "  - 2nd Closest (or tied for 2nd): 20 points",
                "  - 3rd Closest (or tied for 3rd): 10 points",
                "Guesses not falling into these top tiers for a category receive 0 points for that category.",
                "Notes: Time is compared in total minutes. Weight is compared in total ounces.",
              ],
            ),
            _buildRuleSection(
              context,
              title: '2. Hair Color Guess:',
              points: ['Exact Match (from predefined list): 20 points'],
            ),
            _buildRuleSection(
              context,
              title: '3. Eye Color Guess:',
              points: ['Exact Match (from predefined list): 20 points'],
            ),
            _buildRuleSection(
              context,
              title: '4. Who Baby Looks Like (Mom or Dad):',
              points: ['Correct Guess: 20 points'],
            ),
            _buildRuleSection(
              context,
              title: '5. Brycen\'s Reaction (if applicable):',
              points: ['Correct Guess (from predefined list): 1 bonus point'],
            ),
            const SizedBox(height: 24.0),
            Text(
              'Feedback Welcome!',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            Text(
              'These rules are just a starting point. Please share any thoughts, suggestions, or concerns.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Your Feedback',
                hintText: 'Enter your thoughts here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12.0),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitFeedback,
                    child: const Text('Submit Feedback'),
                  ),
            const SizedBox(height: 24.0),
            if (canViewFeedback) _buildFeedbackList(context, ref), // Display feedback list if authorized
          ],
        ),
      ),
    );
  }

  Widget _buildRuleSection(BuildContext context, {required String title, required List<String> points}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4.0),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 2.0),
            child: Text('• $point', style: textTheme.bodyMedium),
          )),
        ],
      ),
    );
  }

  // New widget to display feedback list
  Widget _buildFeedbackList(BuildContext context, WidgetRef ref) {
    final feedbackAsyncValue = ref.watch(feedbackStreamProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submitted Feedback',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 12.0),
        feedbackAsyncValue.when(
          data: (feedbackItems) {
            if (feedbackItems.isEmpty) {
              return const Text('No feedback submitted yet.');
            }
            return ListView.builder(
              shrinkWrap: true, // Important for ListView inside SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling for the inner list
              itemCount: feedbackItems.length,
              itemBuilder: (context, index) {
                final item = feedbackItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From: ${item.userName} (${item.userEmail})',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Date: ${DateFormat('MMM d, yyyy - hh:mm a').format(item.timestamp.toDate())}',
                          style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                        if (item.appVersion != null) Text('App Version: ${item.appVersion}', style: textTheme.bodySmall),
                        if (item.platform != null) Text('Platform: ${item.platform}', style: textTheme.bodySmall),
                        const SizedBox(height: 8.0),
                        Text(item.feedbackText, style: textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error loading feedback: ${err.toString()}', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
} 