
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  String? message;
  Timestamp? timestamp;

  NotificationModel({
    required this.message,
    required this.timestamp,
  });

  // Create from Firestore document
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      message: json['message'],
      timestamp: json['timestamp'] is Timestamp
          ? json['timestamp']
          : Timestamp.fromDate(DateTime.parse(json['timestamp'])),
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'timestamp': timestamp ?? Timestamp.now(),
    };
  }

  // Convert to Map with DateTime for app usage
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'timestamp': timestamp?.toDate(),
    };
  }
}
