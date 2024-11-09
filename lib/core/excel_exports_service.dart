import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExcelExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache to store data and reduce reads
  final Map<String, Map<String, dynamic>> _usersCache = {};
  final Map<String, List<Map<String, dynamic>>> _marksCache = {};
  final Map<String, List<Map<String, dynamic>>> _subscriptionsCache = {};

  Future<void> exportUsersData() async {
    final excel = Excel.createExcel();
    final Sheet usersSheet = excel['Users'];
    final Sheet marksSheet = excel['Marks'];
    final Sheet subscriptionsSheet = excel['Subscriptions'];

    // Set up headers
    _setHeaders(usersSheet, ['User ID', 'Name', 'Phone', 'Total Hours', 'Last Attendance']);
    _setHeaders(marksSheet, ['User ID', 'Student Name', 'Mark', 'Exam Range', 'Date']);
    _setHeaders(subscriptionsSheet, ['User ID', 'Student Name', 'Amount', 'Status', 'Date']);

    try {
      // 1. First, get all users in a single query
      final usersSnapshot = await _firestore
          .collection('users')
          .get();

      final List<String> userIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      // Store users in cache
      for (var doc in usersSnapshot.docs) {
        _usersCache[doc.id] = doc.data();
      }

      // 2. Batch fetch marks and subscriptions for all users
      await Future.wait([
        _batchFetchMarks(userIds),
        _batchFetchSubscriptions(userIds),
      ]);

      // 3. Write data to Excel sheets
      int userRow = 1;
      int marksRow = 1;
      int subscriptionsRow = 1;

      // Write user data
      for (var userId in userIds) {
        final userData = _usersCache[userId]!;
        await _addUserRow(usersSheet, userRow++, userId, userData);

        // Write marks data
        final userMarks = _marksCache[userId] ?? [];
        for (var markData in userMarks) {
          await _addMarkRow(
            marksSheet,
            marksRow++,
            userId,
            '${userData['fname']} ${userData['lname']}',
            markData,
          );
        }

        // Write subscriptions data
        final userSubscriptions = _subscriptionsCache[userId] ?? [];
        for (var subscriptionData in userSubscriptions) {
          await _addSubscriptionRow(
            subscriptionsSheet,
            subscriptionsRow++,
            userId,
            '${userData['fname']} ${userData['lname']}',
            subscriptionData,
          );
        }
      }

      // Save and share file
      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/users_data.xlsx';
      final List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        final File file = File(filePath);
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(filePath)], subject: 'Users Data Export');
      }

    } catch (e) {
      print('Error exporting data: $e');
      throw Exception('Failed to export data: $e');
    } finally {
      // Clear caches
      _usersCache.clear();
      _marksCache.clear();
      _subscriptionsCache.clear();
    }
  }

  Future<void> _batchFetchMarks(List<String> userIds) async {
    // Use batched reads to get marks for all users
    final List<Future<QuerySnapshot>> marksFutures = [];

    for (var userId in userIds) {
      marksFutures.add(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('marks')
              .orderBy('timestamp', descending: true)
              .get()
      );
    }

    final marksResults = await Future.wait(marksFutures);

    // Store in cache
    for (var i = 0; i < userIds.length; i++) {
      _marksCache[userIds[i]] = marksResults[i].docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    }
  }

  Future<void> _batchFetchSubscriptions(List<String> userIds) async {
    // Use batched reads to get subscriptions for all users
    final List<Future<QuerySnapshot>> subscriptionsFutures = [];

    for (var userId in userIds) {
      subscriptionsFutures.add(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('subscriptions')
              .orderBy('timestamp', descending: true)
              .get()
      );
    }

    final subscriptionsResults = await Future.wait(subscriptionsFutures);

    // Store in cache
    for (var i = 0; i < userIds.length; i++) {
      _subscriptionsCache[userIds[i]] = subscriptionsResults[i].docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    }
  }

  // Rest of the helper methods remain the same
  void _setHeaders(Sheet sheet, List<String> headers) {
    // ... [same implementation]
  }

  Future<void> _addUserRow(Sheet sheet, int row, String userId, Map<String, dynamic> userData) async {
    // ... [same implementation]
  }

  Future<void> _addMarkRow(Sheet sheet, int row, String userId, String studentName,
      Map<String, dynamic> markData) async {
    // ... [same implementation]
  }

  Future<void> _addSubscriptionRow(Sheet sheet, int row, String userId, String studentName,
      Map<String, dynamic> subscriptionData) async {
    // ... [same implementation]
  }
}