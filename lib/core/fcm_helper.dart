import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FCMService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID',
    validateStatus: (status) => status! < 500,
  ));

  // Get OAuth2 access token
  static Future<String> getAccessToken() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      return token ?? '';
    } catch (e) {
      print('Error getting access token: $e');
      rethrow;
    }
  }

  static Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final accessToken = await getAccessToken();

      _dio.options.headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      await _dio.post(
        '/messages:send',
        data: {
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data ?? {},
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'attendance_channel',
                'priority': 'high',
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                },
              },
            },
          },
        },
      );
    } on DioException catch (e) {
      print('FCM Error: ${e.message}');
      if (e.response?.statusCode == 404) {
        // Token is invalid
        await _handleInvalidToken(token);
      }
    }
  }

  static Future<void> _handleInvalidToken(String token) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('deviceTokens', arrayContains: token)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'deviceTokens': FieldValue.arrayRemove([token])
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error removing invalid token: $e');
    }
  }
}