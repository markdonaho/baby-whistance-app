import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions; // Optional actions for the AppBar

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        // Potentially add background color from theme or other styling
      ),
      body: body,
      // We could add a common FloatingActionButton or BottomNavigationBar here later if needed
    );
  }
} 