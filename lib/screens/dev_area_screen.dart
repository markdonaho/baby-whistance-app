import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DevAreaScreen extends ConsumerWidget {
  const DevAreaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

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
            const SizedBox(height: 12.0),
            _buildRuleSection(
              context,
              title: '1. Date Guess:',
              points: [
                'Exact Match: 50 points',
                '+/- 1 Day: 25 points',
                '+/- 2 Days: 10 points',
              ],
            ),
            _buildRuleSection(
              context,
              title: '2. Time Guess (within the correct day):',
              points: [
                'Exact Hour & Minute: 40 points',
                'Correct Hour, +/- 15 mins: 20 points',
                'Correct Hour, +/- 30 mins: 10 points',
                '+/- 1 Hour (of actual time): 5 points',
              ],
            ),
            _buildRuleSection(
              context,
              title: '3. Weight Guess (Lbs & Oz):',
              points: [
                'Exact Lbs & Oz: 60 points',
                '+/- 2 oz (from actual total oz): 30 points',
                '+/- 4 oz (from actual total oz): 15 points',
                '+/- 8 oz (from actual total oz): 5 points',
                '(Note: Weight will be converted to total ounces for scoring calculation)',
              ],
            ),
            _buildRuleSection(
              context,
              title: '4. Length Guess (Inches):',
              points: [
                'Exact Length (to nearest 1/4 inch): 50 points',
                '+/- 0.25 inch: 25 points',
                '+/- 0.5 inch: 10 points',
                '+/- 1 inch: 5 points',
              ],
            ),
            _buildRuleSection(
              context,
              title: '5. Hair Color Guess:',
              points: ['Exact Match (from predefined list): 20 points'],
            ),
            _buildRuleSection(
              context,
              title: '6. Eye Color Guess:',
              points: ['Exact Match (from predefined list): 20 points'],
            ),
            _buildRuleSection(
              context,
              title: '7. Who Baby Looks Like (Mom or Dad):',
              points: ['Correct Guess: 15 points'],
            ),
            _buildRuleSection(
              context,
              title: '8. Brycen\'s Reaction (if applicable):',
              points: ['Closest Guess (from predefined list): 10 points (Subjective, for fun!)'],
            ),
            const SizedBox(height: 24.0),
            Text(
              'Feedback Welcome!',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            Text(
              'These rules are just a starting point. Please share any thoughts, suggestions, or concerns. The goal is to make it fun and engaging for everyone!',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement feedback mechanism (e.g., mailto, form, etc.)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback mechanism not yet implemented.')),
                );
              },
              child: const Text('Provide Feedback (Not Implemented)'),
            ),
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
} 