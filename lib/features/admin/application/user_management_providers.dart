import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to get the Firestore instance
// This assumes firebaseFirestoreInstanceProvider is globally available and correctly set up.
// If not, you might need to pass it or create it here.

// StreamProvider that fetches all users from the 'users' collection
final allUsersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  final firestore = ref.watch(firebaseFirestoreInstanceProvider);
  return firestore.collection('users').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc, null)).toList();
  });
}); 