import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';

class UploadPhotoScreen extends StatelessWidget {
  const UploadPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Upload Photo',
      body: const Center(child: Text('Upload Photo Screen')),
      showBottomNavBar: true,
    );
  }
} 