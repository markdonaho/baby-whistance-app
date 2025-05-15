import 'package:cloud_firestore/cloud_firestore.dart';

class Guess {
  final String? id; // Document ID from Firestore
  final String userId;
  final Timestamp submittedAt;
  final Timestamp? lastEditedAt;
  final Timestamp dateGuess;
  final String timeGuess; // Consider storing as Timestamp or DateTime if precision matters
  final int weightGuess; // Total ounces
  final int lengthGuess; // Changed from double to int (total inches)
  final String hairColorGuess;
  final String eyeColorGuess;
  final String looksLikeGuess;
  final String? brycenReactionGuess;

  // Added for scoring
  final int? totalScore;
  final Map<String, dynamic>? scoreBreakdown;

  Guess({
    this.id,
    required this.userId,
    required this.submittedAt,
    this.lastEditedAt,
    required this.dateGuess,
    required this.timeGuess,
    required this.weightGuess,
    required this.lengthGuess, // Now int
    required this.hairColorGuess,
    required this.eyeColorGuess,
    required this.looksLikeGuess,
    this.brycenReactionGuess,
    this.totalScore, // Added
    this.scoreBreakdown, // Added
  });

  // Factory constructor to create a Guess from a Firestore document
  factory Guess.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return Guess(
      id: snapshot.id,
      userId: data?['userId'] as String,
      submittedAt: data?['submittedAt'] as Timestamp,
      lastEditedAt: data?['lastEditedAt'] as Timestamp?,
      dateGuess: data?['dateGuess'] as Timestamp,
      timeGuess: data?['timeGuess'] as String,
      weightGuess: (data?['weightGuess'] as num?)?.toInt() ?? 0,
      lengthGuess: (data?['lengthGuess'] as num?)?.toInt() ?? 0, // Changed to toInt(), default to 0
      hairColorGuess: data?['hairColorGuess'] as String? ?? '',
      eyeColorGuess: data?['eyeColorGuess'] as String? ?? '',
      looksLikeGuess: data?['looksLikeGuess'] as String? ?? '',
      brycenReactionGuess: data?['brycenReactionGuess'] as String?,
      // Added for scoring
      totalScore: (data?['total_score'] as num?)?.toInt(), // Firestore field is likely total_score
      scoreBreakdown: data?['score_breakdown'] as Map<String, dynamic>?, // Firestore field is likely score_breakdown
    );
  }

  // Method to convert a Guess instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'submittedAt': submittedAt,
      if (lastEditedAt != null) 'lastEditedAt': lastEditedAt,
      'dateGuess': dateGuess,
      'timeGuess': timeGuess,
      'weightGuess': weightGuess,
      'lengthGuess': lengthGuess, // Now int
      'hairColorGuess': hairColorGuess,
      'eyeColorGuess': eyeColorGuess,
      'looksLikeGuess': looksLikeGuess,
      if (brycenReactionGuess != null) 'brycenReactionGuess': brycenReactionGuess,
      // Note: totalScore and scoreBreakdown are typically written by a backend function,
      // so they are not included here. If client-side updates were needed, they'd be added.
    };
  }

  // Optional: A copyWith method can be useful for updating instances
  Guess copyWith({
    String? id,
    String? userId,
    Timestamp? submittedAt,
    Timestamp? lastEditedAt,
    Timestamp? dateGuess,
    String? timeGuess,
    int? weightGuess,
    int? lengthGuess, // Changed to int?
    String? hairColorGuess,
    String? eyeColorGuess,
    String? looksLikeGuess,
    String? brycenReactionGuess,
    bool setBrycenReactionToNull = false,
    // Added for scoring
    int? totalScore,
    Map<String, dynamic>? scoreBreakdown,
  }) {
    return Guess(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      submittedAt: submittedAt ?? this.submittedAt,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      dateGuess: dateGuess ?? this.dateGuess,
      timeGuess: timeGuess ?? this.timeGuess,
      weightGuess: weightGuess ?? this.weightGuess,
      lengthGuess: lengthGuess ?? this.lengthGuess, // Now int
      hairColorGuess: hairColorGuess ?? this.hairColorGuess,
      eyeColorGuess: eyeColorGuess ?? this.eyeColorGuess,
      looksLikeGuess: looksLikeGuess ?? this.looksLikeGuess,
      brycenReactionGuess: setBrycenReactionToNull ? null : (brycenReactionGuess ?? this.brycenReactionGuess),
      // Added for scoring
      totalScore: totalScore ?? this.totalScore,
      scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
    );
  }
} 