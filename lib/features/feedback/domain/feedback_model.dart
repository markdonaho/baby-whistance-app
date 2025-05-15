import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackItem {
  final String? id;
  final String userId;
  final String userName; // Denormalized for easier display
  final String userEmail; // Denormalized for easier display
  final Timestamp timestamp;
  final String feedbackText;
  final String? appVersion; // Optional: to know which version the feedback is for
  final String? platform; // Optional: e.g., 'web', 'ios', 'android'

  FeedbackItem({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.timestamp,
    required this.feedbackText,
    this.appVersion,
    this.platform,
  });

  factory FeedbackItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return FeedbackItem(
      id: snapshot.id,
      userId: data?['userId'] as String,
      userName: data?['userName'] as String? ?? 'Unknown User',
      userEmail: data?['userEmail'] as String? ?? 'No email',
      timestamp: data?['timestamp'] as Timestamp,
      feedbackText: data?['feedbackText'] as String,
      appVersion: data?['appVersion'] as String?,
      platform: data?['platform'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'timestamp': timestamp,
      'feedbackText': feedbackText,
      if (appVersion != null) 'appVersion': appVersion,
      if (platform != null) 'platform': platform,
    };
  }
} 