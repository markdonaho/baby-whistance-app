import 'package:cloud_firestore/cloud_firestore.dart';

// Defines the roles for users in the application.
enum AppUserRole { user, admin, whistance }

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final AppUserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AppUser(
      uid: snapshot.id, // or data?['uid'] if you store it as a field
      email: data?['email'],
      displayName: data?['displayName'],
      role: AppUserRole.values.firstWhere(
        (e) => e.toString() == 'AppUserRole.' + data?['role'],
        orElse: () => AppUserRole.user, // Default to user if role is missing or invalid
      ),
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data?['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) "email": email,
      if (displayName != null) "displayName": displayName,
      "role": role.toString().split('.').last, // Stores the role as a string e.g. "user"
      "createdAt": createdAt, // Use existing createdAt, or FieldValue.serverTimestamp() for new
      "updatedAt": FieldValue.serverTimestamp(), // Let Firestore set/update the modification time
    };
  }

  // Helper to create an initial AppUser, typically after signup
  static AppUser initial({
    required String uid,
    String? email,
    String? displayName,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: AppUserRole.user, // Default role for new users
      createdAt: DateTime.now(), // This will be set by serverTimestamp on first write ideally
    );
  }

  // CopyWith method for immutability if needed later
  AppUser copyWith({
    String? displayName,
    AppUserRole? role,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt, // createdAt should not change
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 