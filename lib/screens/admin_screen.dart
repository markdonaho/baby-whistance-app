import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:baby_whistance_app/config/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baby_whistance_app/features/app_status/app_status_service.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  void _showChangeGuessingStatusDialog(BuildContext context, WidgetRef ref, GuessingStatus currentStatus) {
    GuessingStatus selectedStatus = currentStatus;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Change Guessing Status'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<GuessingStatus>(
                value: selectedStatus,
                onChanged: (GuessingStatus? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStatus = newValue;
                    });
                  }
                },
                items: GuessingStatus.values.map<DropdownMenuItem<GuessingStatus>>((GuessingStatus value) {
                  return DropdownMenuItem<GuessingStatus>(
                    value: value,
                    child: Text(value.toString().split('.').last),
                  );
                }).toList(),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                try {
                  await ref.read(appStatusServiceProvider.notifier).setGuessingStatus(selectedStatus);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Guessing status updated to ${selectedStatus.toString().split('.').last}')),
                  );
                } catch (e) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update status: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStatusAsync = ref.watch(currentAppStatusProvider);

    return AppScaffold(
      title: 'Admin Panel',
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            subtitle: const Text('View and manage user roles'),
            onTap: () {
              context.goNamed(AppRoute.adminUserManagement.name);
            },
          ),
          appStatusAsync.when(
            data: (status) => ListTile(
              leading: const Icon(Icons.settings_applications),
              title: const Text('Guessing Status'),
              subtitle: Text('Current: ${status.guessingStatus.toString().split('.').last}'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                _showChangeGuessingStatusDialog(context, ref, status.guessingStatus);
              },
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.settings_applications),
              title: Text('Guessing Status'),
              subtitle: Text('Loading...'),
              trailing: CircularProgressIndicator(),
            ),
            error: (err, stack) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Guessing Status'),
              subtitle: Text('Error: ${err.toString()}'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.child_care),
            title: const Text('Enter Actual Baby Details'),
            subtitle: const Text('Record the baby\'s arrival information'),
            onTap: () {
              context.goNamed(AppRoute.adminEnterBabyDetails.name);
            },
          ),
          // Add other admin functionalities here as ListTiles
        ],
      ),
      showBottomNavBar: true,
    );
  }
} 