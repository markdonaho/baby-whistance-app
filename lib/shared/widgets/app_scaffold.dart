import 'package:baby_whistance_app/shared/widgets/app_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';

class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final bool showBottomNavBar;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBottomNavBar = true,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> appBarActions = [
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: 'Logout',
        onPressed: () async {
          await ref.read(authControllerProvider.notifier).signOut();
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: appBarActions,
      ),
      body: body,
      bottomNavigationBar: showBottomNavBar ? const AppBottomNavBar() : null,
      floatingActionButton: floatingActionButton,
    );
  }
} 