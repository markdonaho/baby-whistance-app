import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Admin',
      body: const Center(child: Text('Admin Screen')),
      showBottomNavBar: false, 
    );
  }
} 