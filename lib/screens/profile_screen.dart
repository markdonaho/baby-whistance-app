import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      body: const Center(child: Text('Profile Screen')),
      showBottomNavBar: true,
    );
  }
} 