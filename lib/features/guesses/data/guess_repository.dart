import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart'; // For appUserProvider
import 'package:baby_whistance_app/features/guesses/domain/guess_model.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final guessRepositoryProvider = Provider<GuessRepository>((ref) {
  return GuessRepository(ref.watch(firestoreProvider));
});

class GuessRepository {
  final FirebaseFirestore _firestore;

  GuessRepository(this._firestore);

  Future<void> addGuess(Guess guess, String userId) async {
    try {
      // All guesses go into a top-level 'guesses' collection.
      // The Guess object itself should contain the userId.
      await _firestore.collection('guesses').add(guess.toFirestore());
    } catch (e) {
      // TODO: Handle exceptions more gracefully
      print('Error adding guess to Firestore: $e');
      rethrow;
    }
  }

  // Method to get a stream of a specific user's guesses, ordered by submission time
  Stream<List<Guess>> getUserGuessesStream(String userId) {
    try {
      return _firestore
          .collection('guesses') // Query top-level 'guesses' collection
          .where('userId', isEqualTo: userId) // Filter by userId
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          // Pass doc.id as the guessId if your model needs it
          return Guess.fromFirestore(doc, null); 
        }).toList();
      });
    } catch (e) {
      print('Error fetching user guesses: $e');
      return Stream.value([]);
    }
  }

  // Method to get a stream of all guesses from all users, ordered by submission time
  Stream<List<Guess>> getAllGuessesStream() {
    try {
      return _firestore
          .collection('guesses') // Query top-level 'guesses' collection
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          // Pass doc.id as the guessId if your model needs it
          return Guess.fromFirestore(doc, null);
        }).toList();
      });
    } catch (e) {
      print('Error fetching all guesses: $e');
      return Stream.value([]);
    }
  }

  Future<void> updateGuess(Guess guess) async {
    if (guess.id == null) {
      throw ArgumentError('Guess ID cannot be null when updating a guess.');
    }
    try {
      await _firestore
          .collection('guesses')
          .doc(guess.id)
          .update(guess.toFirestore()); // Assumes toFirestore() provides all updatable fields
    } catch (e) {
      print('Error updating guess in Firestore: $e');
      rethrow;
    }
  }

  // TODO: Add methods for updating, deleting, etc.
} 