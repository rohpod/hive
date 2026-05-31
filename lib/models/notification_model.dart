import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String eventId;
  final String message;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.message,
    required this.timestamp,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json, String documentId) {
    return NotificationModel(
      id: documentId,
      userId: json['userId'] ?? '',
      eventId: json['eventId'] ?? '',
      message: json['message'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'eventId': eventId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
