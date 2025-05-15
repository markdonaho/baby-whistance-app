import 'package:flutter/material.dart';

class DevAreaScreen extends StatelessWidget {
  const DevAreaScreen({super.key});

  static const routeName = '/dev-area'; // For GoRouter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Area & Scoring Rules'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Proposed Scoring Rules (Under Development)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to the development area! Below are some initial thoughts on how scoring might work. '
              'This is all subject to change and your feedback is highly appreciated!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              'Points System (Example):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Exact Date: 50 points'),
            Text('• Exact Time (within 15 mins): 30 points'),
            Text('• Exact Weight (within 2 oz): 25 points'),
            Text('• Exact Length (within 0.5 inch): 25 points'),
            Text('• Correct Hair Color: 15 points'),
            Text('• Correct Eye Color: 15 points'),
            Text('• Correct "Looks Like": 10 points'),
            Text('• Brycen\'s Reaction (if applicable and correct): 5 points (just for fun!)'),
            SizedBox(height: 16),
            Text(
              'Bonus Points:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• "The Oracle" (All categories correct): Additional 100 points!'),
            SizedBox(height: 24),
            Text(
              'Feedback:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'What do you think? Any suggestions for improving the scoring, adding new categories, '
              'or other fun ideas? Let Mark or Katie know!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '(Note: This screen is for informational and feedback purposes only during development. '
              'Actual scoring implementation will come later.)',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
} 