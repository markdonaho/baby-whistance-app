import 'package:baby_whistance_app/features/auth/auth_service_consolidated.dart';
import 'package:baby_whistance_app/features/guesses/data/guess_repository.dart';
import 'package:baby_whistance_app/features/guesses/domain/guess_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the GuessController
final guessControllerProvider = StateNotifierProvider<GuessController, AsyncValue<void>>((ref) {
  final guessRepository = ref.watch(guessRepositoryProvider);
  final user = ref.watch(authControllerProvider).value; // Get current Firebase User
  return GuessController(guessRepository, user?.uid);
});

class GuessController extends StateNotifier<AsyncValue<void>> {
  final GuessRepository _guessRepository;
  final String? _userId; // Store userId to pass to repository

  GuessController(this._guessRepository, this._userId) : super(const AsyncData(null));

  Future<bool> submitGuess({
    required Timestamp dateGuess,
    required String timeGuess,
    required int weightGuess,
    required int lengthGuess,
    required String hairColorGuess,
    required String eyeColorGuess,
    required String looksLikeGuess,
    String? brycenReactionGuess,
  }) async {
    if (_userId == null) {
      state = AsyncError('User not logged in', StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    try {
      final newGuess = Guess(
        userId: _userId!, // We know _userId is not null here
        submittedAt: Timestamp.now(), // Set current time as submission time
        // lastEditedAt will be null on creation
        dateGuess: dateGuess,
        timeGuess: timeGuess,
        weightGuess: weightGuess,
        lengthGuess: lengthGuess,
        hairColorGuess: hairColorGuess,
        eyeColorGuess: eyeColorGuess,
        looksLikeGuess: looksLikeGuess,
        brycenReactionGuess: brycenReactionGuess,
      );
      await _guessRepository.addGuess(newGuess, _userId!); 
      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<bool> updateGuess({
    required String guessId, // ID of the guess to update
    required Timestamp dateGuess,
    required String timeGuess,
    required int weightGuess,
    required int lengthGuess,
    required String hairColorGuess,
    required String eyeColorGuess,
    required String looksLikeGuess,
    String? brycenReactionGuess,
  }) async {
    if (_userId == null) {
      state = AsyncError('User not logged in', StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    try {
      final updatedGuess = Guess(
        id: guessId, // Pass the existing ID
        userId: _userId!, 
        submittedAt: Timestamp.now(), // Consider if submittedAt should be updated or a new lastEditedAt field added
        // For now, we'll update submittedAt to reflect the latest edit time.
        // If you need to preserve original submission time, add a 'lastEditedAt' field to Guess model.
        dateGuess: dateGuess,
        timeGuess: timeGuess,
        weightGuess: weightGuess,
        lengthGuess: lengthGuess,
        hairColorGuess: hairColorGuess,
        eyeColorGuess: eyeColorGuess,
        looksLikeGuess: looksLikeGuess,
        brycenReactionGuess: brycenReactionGuess,
      );
      await _guessRepository.updateGuess(updatedGuess);
      state = const AsyncData(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  // TODO: Add methods for fetching/managing guess state if needed beyond submission
}

// Provider to get the stream of user's guesses
final userGuessesStreamProvider = StreamProvider.autoDispose<List<Guess>>((ref) {
  final guessRepository = ref.watch(guessRepositoryProvider);
  final authState = ref.watch(authControllerProvider); // Watch the auth state

  final userId = authState.asData?.value?.uid;

  if (userId != null) {
    return guessRepository.getUserGuessesStream(userId);
  } else {
    // If user is not logged in, return an empty stream or handle as appropriate
    return Stream.value([]);
  }
});

// Provider to get the stream of all guesses from all users
final allGuessesStreamProvider = StreamProvider.autoDispose<List<Guess>>((ref) {
  final guessRepository = ref.watch(guessRepositoryProvider);
  // No user ID needed, just fetch all guesses.
  // Add any necessary error handling or loading states if desired.
  return guessRepository.getAllGuessesStream();
}); 