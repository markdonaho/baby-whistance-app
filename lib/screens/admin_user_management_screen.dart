import 'package:baby_whistance_app/features/admin/application/user_management_providers.dart';
import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baby_whistance_app/shared/widgets/app_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Firestore instance

// Simple provider for a user management service (to be created)
final userManagementServiceProvider = Provider((ref) {
  return UserManagementService(ref.watch(firebaseFirestoreInstanceProvider));
});

class UserManagementService {
  final FirebaseFirestore _firestore;
  UserManagementService(this._firestore);

  Future<void> updateUserRole(String userId, AppUserRole newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(), // Keep updatedAt consistent
      });
    } catch (e) {
      // Handle or rethrow the error appropriately
      print('Error updating user role: $e');
      rethrow;
    }
  }
}

class AdminUserManagementScreen extends ConsumerWidget {
  const AdminUserManagementScreen({super.key});

  void _showChangeRoleDialog(BuildContext context, WidgetRef ref, AppUser user) {
    AppUserRole selectedRole = user.role;
    bool _isSavingRole = false; // Local state for dialog save button

    showDialog(
      context: context,
      barrierDismissible: !_isSavingRole, // Prevent dismissing while saving
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Wrap AlertDialog with StatefulBuilder
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text('Change Role for ${user.displayName ?? user.email}'),
              content: DropdownButton<AppUserRole>(
                  value: selectedRole,
                  onChanged: _isSavingRole ? null : (AppUserRole? newValue) { // Disable dropdown while saving
                    if (newValue != null) {
                      setStateDialog(() {
                        selectedRole = newValue;
                      });
                    }
                  },
                  items: AppUserRole.values.map<DropdownMenuItem<AppUserRole>>((AppUserRole value) {
                    return DropdownMenuItem<AppUserRole>(
                      value: value,
                      child: Text(value.toString().split('.').last),
                    );
                  }).toList(),
                ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: _isSavingRole ? null : () { // Disable cancel while saving
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: _isSavingRole ? null : () async { // Disable save while saving
                    setStateDialog(() {
                      _isSavingRole = true;
                    });
                    try {
                      await ref.read(userManagementServiceProvider).updateUserRole(user.uid, selectedRole);
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Role for ${user.displayName ?? user.email} updated to ${selectedRole.toString().split('.').last}')),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update role: ${e.toString()}')),
                      );
                    } finally {
                      // No need to set _isSavingRole back if dialog is popped.
                    }
                  },
                  child: _isSavingRole
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
    final allUsersAsync = ref.watch(allUsersStreamProvider);
    // Get current user to prevent admin from changing their own role via this UI
    final currentAppUser = ref.watch(appUserStreamProvider).asData?.value;

    return AppScaffold(
      title: 'User Management',
      body: allUsersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              // Admin cannot change their own role through this interface
              final bool isCurrentUser = user.uid == currentAppUser?.uid;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.displayName?.substring(0, 1).toUpperCase() ?? 'U'),
                ),
                title: Text(user.displayName ?? user.email ?? 'N/A'),
                subtitle: Text('${user.email ?? 'No email'} - Role: ${user.role.toString().split('.').last}'),
                trailing: isCurrentUser
                    ? null // No edit button for the currently logged-in admin
                    : IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Change Role',
                        onPressed: () {
                          _showChangeRoleDialog(context, ref, user);
                        },
                      ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          // Log the error for debugging
          print('Error fetching users: $error\n$stackTrace');
          return Center(
            child: Text('Error loading users. Ensure Firestore rules allow admin access to the users collection. Error: ${error.toString()}'),
          );
        },
      ),
    );
  }
} 