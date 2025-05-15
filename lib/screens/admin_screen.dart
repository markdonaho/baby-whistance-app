import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:baby_whistance_app/config/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baby_whistance_app/features/app_status/app_status_service.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Added for Firebase Functions

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  // Method to trigger score calculation
  Future<void> _triggerScoreCalculation(BuildContext context, WidgetRef ref) async {
    final appStatus = ref.read(currentAppStatusProvider).asData?.value;
    if (appStatus?.guessingStatus != GuessingStatus.revealed || appStatus?.actualBabyDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please ensure actual baby details are entered and guessing status is "revealed" before calculating scores.')),
      );
      return;
    }

    final bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Score Calculation'),
        content: const Text('This will calculate and save scores for all guesses based on the current actual baby details. This action cannot be undone. Proceed?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Yes, Calculate Scores'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calculating scores... This may take a moment.')),
    );

    try {
      final functions = FirebaseFunctions.instance;
      final HttpsCallable callable = functions.httpsCallable('calculateAndSaveScores');
      final HttpsCallableResult result = await callable.call(); 
      
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.data['message'] as String? ?? 'Scores processed successfully!')),
      );
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating scores: ${e.message} (Code: ${e.code})')),
      );
      debugPrint('Cloud Function Error: ${e.code} - ${e.message} - Details: ${e.details}');
    } catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
      );
      debugPrint('Generic Error calling score function: ${e.toString()}');
    }
  }

  void _showChangeGuessingStatusDialog(BuildContext context, WidgetRef ref, GuessingStatus currentStatus) {
    GuessingStatus selectedStatus = currentStatus;
    bool _isSavingStatus = false; // Local state for dialog save button

    showDialog(
      context: context,
      barrierDismissible: !_isSavingStatus, // Prevent dismissing while saving
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(// Wrap AlertDialog with StatefulBuilder to manage _isSavingStatus
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Change Guessing Status'),
              content: DropdownButton<GuessingStatus>(
                  value: selectedStatus,
                  onChanged: _isSavingStatus ? null : (GuessingStatus? newValue) { // Disable dropdown while saving
                    if (newValue != null) {
                      // This setState is for the DropdownButton itself if it were inside its own StatefulBuilder
                      // For this dialog structure, we use setStateDialog from the outer StatefulBuilder
                      setStateDialog(() {
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
                ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: _isSavingStatus ? null : () { // Disable cancel while saving
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: _isSavingStatus ? null : () async { // Disable save while saving
                    setStateDialog(() {
                      _isSavingStatus = true;
                    });
                    try {
                      await ref.read(appStatusServiceProvider.notifier).setGuessingStatus(selectedStatus);
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Guessing status updated to ${selectedStatus.toString().split('.').last}')),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update status: ${e.toString()}')),
                      );
                    } finally {
                      // No need to set _isSavingStatus back to false if dialog is popped,
                      // but if there was a scenario it didn't pop on error, it would be needed.
                      // setStateDialog(() => _isSavingStatus = false); // Usually not needed if pop occurs
                    }
                  },
                  child: _isSavingStatus 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Save'),
                ),
              ],
            );
          }
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
          // ListTile to trigger score calculation
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Calculate & Save Scores'),
            subtitle: const Text('Calculates scores for all guesses. Run after details are revealed.'),
            onTap: () {
              _triggerScoreCalculation(context, ref);
            },
          ),
          // Add other admin functionalities here as ListTiles
        ],
      ),
      showBottomNavBar: true,
    );
  }
} 