
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FCMService {
  static final Dio _dio = Dio(BaseOptions(
    validateStatus: (status) => status! < 500,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Get OAuth2 token using Firebase Auth
  static Future<String?> getAccessToken() async {
    try {
      // Get the current Firebase user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      // Get the ID token with Firebase Auth
      return await user.getIdToken();
    } catch (e) {
      print('Error getting access token: $e');
      rethrow;
    }
  }

  static Future<void> sendNotification({
    required List<String> deviceTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final accessToken = await getAccessToken();
      final projectId = await _getProjectId();

      _dio.options.baseUrl = 'https://fcm.googleapis.com/v1/projects/$projectId';
      _dio.options.headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final List<Future<Response>> requests = deviceTokens.map((token) {
        return _dio.post(
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
                'notification': {
                  'channel_id': 'high_importance_channel',
                  'priority': 'high',
                  'default_sound': true,
                  'default_vibrate_timings': true,
                  'notification_priority': 'PRIORITY_HIGH',
                },
              },
              'apns': {
                'headers': {
                  'apns-priority': '10',
                },
                'payload': {
                  'aps': {
                    'alert': {
                      'title': title,
                      'body': body,
                    },
                    'sound': 'default',
                    'badge': 1,
                    'content-available': 1,
                  },
                },
              },
              'webpush': {
                'notification': {
                  'title': title,
                  'body': body,
                  'icon': 'your-icon-url',
                },
              },
            },
          },
        );
      }).toList();

      // Send notifications in parallel
      final responses = await Future.wait(
        requests,
        eagerError: false,
      ).catchError((e) {
        print('Error sending batch notifications: $e');
        return <Response>[];
      });

      // Process responses
      for (var i = 0; i < responses.length; i++) {
        try {
          final response = responses[i];
          final token = deviceTokens[i];

          if (response.statusCode == 200) {
            print('Successfully sent notification to token: $token');
          } else {
            print('Failed to send FCM to token $token: ${response.data}');

            if (_isInvalidToken(response.data)) {
              await _handleInvalidToken(token);
            }
          }
        } catch (e) {
          print('Error processing response for token ${deviceTokens[i]}: $e');
        }
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    } catch (e) {
      print('Unexpected error sending FCM notification: $e');
      rethrow;
    }
  }

  // Get project ID from Firebase configuration
  static Future<String> _getProjectId() async {
    return Firebase.app().options.projectId;
  }

  static bool _isInvalidToken(dynamic responseData) {
    if (responseData is Map) {
      final error = responseData['error']?.toString().toLowerCase();
      return error?.contains('not-registered') == true ||
          error?.contains('invalid-registration') == true ||
          error?.contains('invalid-argument') == true;
    }
    return false;
  }

  static Future<void> _handleInvalidToken(String token) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('deviceToken', arrayContains: token)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'deviceToken': FieldValue.arrayRemove([token])
        });
      }

      await batch.commit();
      print('Removed invalid token: $token');
    } catch (e) {
      print('Error removing invalid token: $e');
    }
  }

  static void _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        print('FCM Connection timeout');
        break;
      case DioExceptionType.sendTimeout:
        print('FCM Send timeout');
        break;
      case DioExceptionType.receiveTimeout:
        print('FCM Receive timeout');
        break;
      case DioExceptionType.badResponse:
        print('FCM Bad response: ${e.response?.data}');
        break;
      case DioExceptionType.cancel:
        print('FCM Request cancelled');
        break;
      default:
        print('FCM Unexpected error: ${e.message}');
    }
  }
}