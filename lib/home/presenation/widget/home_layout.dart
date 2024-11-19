
import 'dart:convert';
import 'dart:html' as html; // For file download in web
import 'dart:typed_data'; // For file encoding
import 'package:excel/excel.dart'; // For creating Excel files
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'dart:convert'; // For UTF-8 encoding
import 'package:admin_future/attendence/presentation/attendence_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/excel_exports_service.dart';
import '../../../core/fcm_helper.dart';
import '../../../manage_users_coaches/presenation/mange_students_screen.dart';

// Main Layout
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart' show kIsWeb, mapEquals;
import 'dart:html' as html;
import 'package:excel/excel.dart' as excel;

import '../../../registeration/data/userModel.dart';



import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:collection/collection.dart';

  class HomeLayout extends StatefulWidget {
    @override
    _HomeLayoutState createState() => _HomeLayoutState();
  }

  class _HomeLayoutState extends State<HomeLayout> {
    int currentIndex = 0;
    final excelExportService = ExcelExportService();
    bool isExporting = false;
    ExcelFirebaseSync? _excelSync;

    final List<Widget> screens = [
      const ManageStudentsScreen(),
      QRScannerScreen(),
      BlocProvider(
        create: (context) => AttendanceCubit()..loadAttendance(DateTime.now()),
        child: AttendanceScreen(),
      ),
    ];

    final List<String> listOfIcons = [
      'assets/images/dashboard-2_svgrepo.com.svg',
      'assets/images/scan-qrcode_svgrepo.com.svg',
      'assets/images/🦆 icon _person_.svg',
    ];

    final List<String> listOfTitles = [
      'الطلاب',
      'مسح QR',
      'الحضور',
    ];

    Future<void> exportUsersAndAttendanceDataAsExcelArabic() async {
      try {
        setState(() => isExporting = true);
        final firestore = FirebaseFirestore.instance;
        var excel = Excel.createExcel();


        // Users sheet
        final usersSheet = excel['المستخدمون'];
        usersSheet.appendRow([
          'الاسم الأول',
          'اسم العائلة',
          'المعرف',
          'رمز المجموعة',
          'رقم واتس الطالب',
          'رقم ولي الامر',
          'مصاريف',
          'ملاحظات'
        ]);

        final usersSnapshot = await firestore
            .collection('users')
            .orderBy('lastModifiedDate', descending: true)
            .get();

        for (var doc in usersSnapshot.docs) {
          var data = doc.data();
          String lastPaymentDateStr = '';
          String notes = '';

          if (data['lastPaymentDate'] != null) {
            DateTime lastPaymentDate = (data['lastPaymentDate'] as Timestamp).toDate();
            DateTime now = DateTime.now();
            if (now.month > lastPaymentDate.month || now.year > lastPaymentDate.year) {
              notes = 'يحتاج المستخدم إلى دفع الاشتراك';
            }
            lastPaymentDateStr = '${lastPaymentDate.year}-${lastPaymentDate.month}-${lastPaymentDate.day}';
          }

          usersSheet.appendRow([
            data['fname'] ?? '',
            data['lname'] ?? '',
            doc.id,
            data['groupCode'] ?? '',
            data['phone'] ?? '',
            data['parentPhone'] ?? '',
            lastPaymentDateStr,
            notes
          ]);

          usersSheet.appendRow(['', '', '', '', '', '', '', '']);
        }

        // Attendance sheet
        final attendanceSheet = excel['سجلات الحضور'];
        attendanceSheet.appendRow([
          'رقم الطالب',
          'اسم الطالب',
          'رمز المجموعة',
          'التاريخ',
          'السنة',
          'الشهر',
          'اليوم',
          'الساعة',
          'الدقيقة'
        ]);

        final attendanceSnapshot = await firestore.collection('attendance').get();

        for (var doc in attendanceSnapshot.docs) {
          var data = doc.data();
          attendanceSheet.appendRow([
            data['studentId'] ?? '',
            data['studentName'] ?? '',
            data['groupCode'] ?? '',
            data['date'] ?? '',
            data['year'] ?? '',
            data['month'] ?? '',
            data['day'] ?? '',
            data['hour'] ?? '',
            data['minute'] ?? ''
          ]);
        }

        var bytes = excel.save();
        final blob = html.Blob([Uint8List.fromList(bytes!)],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Download the file
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'تقرير_بيانات_المستخدمين.xlsx')
          ..click();

        html.Url.revokeObjectUrl(url);

        // Start watching after small delay to ensure file is downloaded
        await Future.delayed(Duration(seconds: 1));

        // Initialize Excel sync
        _excelSync?.stopWatching();
        _excelSync = ExcelFirebaseSync();
        await _excelSync!.watchExcelChanges(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير الملف. قم باختياره للمراقبة'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print('Export error: $e');
        rethrow;
      }
    }

    @override
    void dispose() {
      _excelSync?.stopWatching();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      double screenWidth = MediaQuery.of(context).size.width;

      return Scaffold(
        appBar: currentIndex == 2 || currentIndex == 1
            ? null
            : AppBar(
          backgroundColor: const Color(0xFF4869E8),
          title: Text(
            listOfTitles[currentIndex],
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            if (currentIndex == 0)
              IconButton(
                icon: isExporting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.file_download, color: Colors.white),
                onPressed: isExporting
                    ? null
                    : () async {
                  setState(() => isExporting = true);
                  try {
                    await exportUsersAndAttendanceDataAsExcelArabic();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تصدير البيانات بنجاح'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('حدث خطأ أثناء تصدير البيانات'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } finally {
                    setState(() => isExporting = false);
                  }
                },
              ),
          ],
        ),
        body: screens[currentIndex],
        bottomNavigationBar: Container(
          height: 67.h,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ListView.builder(
            itemCount: 3,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * .06),
            itemBuilder: (context, index) => InkWell(
              onTap: () {
                setState(() {
                  currentIndex = index;
                });
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: screenWidth * .3,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            curve: Curves.fastLinearToSlowEaseIn,
                            height: index == currentIndex ? 32.h : 0,
                            width: index == currentIndex ? screenWidth * .3 : 0,
                            decoration: BoxDecoration(
                              color: index == currentIndex
                                  ? const Color(0xff2196F3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: screenWidth * .3,
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          listOfIcons[index],
                          height: 24.h,
                          width: 24.w,
                          color: index == currentIndex
                              ? const Color(0xffFFFFFF)
                              : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: 64.w,
                    height: 16.h,
                    child: Text(
                      listOfTitles[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: index == currentIndex
                            ? const Color(0xff2196F3)
                            : Colors.black26,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  class ExcelFirebaseSync {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    Timer? _watchTimer;
    html.FileUploadInputElement? _uploadInput;
    Map<String, dynamic>? _lastData;
    html.File? _lastFile;

    Future<void> watchExcelChanges(BuildContext context) async {
      try {
        print('Starting Excel watch process...');

        // Create file input element
        _uploadInput = html.FileUploadInputElement()
          ..accept = '.xlsx'
          ..style.display = 'none';

        html.document.body?.append(_uploadInput!);

        // Setup file selection handler
        _uploadInput!.onChange.listen((event) async {
          if (_uploadInput!.files!.isNotEmpty) {
            _lastFile = _uploadInput!.files![0];
            _lastData = null; // Reset to ensure fresh parsing
            startFileMonitoring(context);

            print('File selected: ${_lastFile?.name}');

            final reader = html.FileReader();
            reader.readAsArrayBuffer(_lastFile!);

            reader.onLoad.listen((event) async {
              try {
                print('Processing selected file...');
                final data = reader.result as List<int>;
                final excel = Excel.decodeBytes(data);
                _lastData = await _parseExcelData(excel);

                print('Initial data loaded, starting monitoring...');
                startFileMonitoring(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم بدء مراقبة الملف'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                print('Error processing file: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ في معالجة الملف: $e')),
                );
              }
            });
          }
        });

        // Show file picker
        _uploadInput!.click();

      } catch (e) {
        print('Error setting up file watch: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إعداد المراقبة: $e')),
        );
      }
    }

    void startFileMonitoring(BuildContext context) {
      _watchTimer?.cancel();
      _watchTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        if (_lastFile != null) {
          try {
            final reader = html.FileReader();
            reader.readAsArrayBuffer(_lastFile!);

            reader.onLoad.listen((event) async {
              final data = reader.result as List<int>;
              final excel = Excel.decodeBytes(data);
              final newData = await _parseExcelData(excel);

              if (_hasRealChanges(_lastData, newData)) {
                print('Changes detected in file');
                await _updateFirebase(newData, context);
                _lastData = newData;
              }
            });
          } catch (e) {
            print('Error checking file changes: $e');
          }
        }
      });
    }

    @override
    void stopWatching() {
      print('Stopping Excel watch');
      _watchTimer?.cancel();
      _watchTimer = null;
      _uploadInput?.remove();
      _uploadInput = null;
      _lastFile = null;
      _lastData = null;
    }

    // Update the export method in your HomeLayout
    Future<void> exportAndWatchExcel(BuildContext context) async {
      try {
        final excel = await _createExcelData();
        final bytes = excel.save();

        if (bytes == null) {
          throw 'Failed to save Excel file';
        }

        // Create blob and download
        final blob = html.Blob([Uint8List.fromList(bytes)],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Download file
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'تقرير_بيانات_المستخدمين.xlsx')
          ..style.display = 'none';

        html.document.body?.append(anchor);
        anchor.click();

        // Cleanup
        html.Url.revokeObjectUrl(url);
        anchor.remove();

        // Show instructions
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل الملف. قم بفتحه وتحديثه ثم اختره للمراقبة'),
            duration: Duration(seconds: 5),
          ),
        );

        // Start watching after a delay
        await Future.delayed(const Duration(seconds: 2));
        await watchExcelChanges(context);

      } catch (e) {
        print('Export error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصدير: $e')),
        );
      }
    }

    // Helper method to create Excel data
    Future<Excel> _createExcelData() async {
      final excel = Excel.createExcel();
      // ... your existing Excel creation code ...
      return excel;
    }



    Future<void> _checkFileChanges(html.File file, BuildContext context) async {
      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        final excel = Excel.decodeBytes(reader.result as List<int>);
        final newData = await _parseExcelData(excel);

        if (_hasRealChanges(_lastData, newData)) {
          print('File content changed!');
          await _updateFirebase(newData, context);
          _lastData = newData;
        }
      } catch (e) {
        print('Error checking file changes: $e');
      }
    }

    // Keep your existing methods for _parseExcelData, _hasRealChanges, etc.



    bool _hasRealChanges(Map<String, dynamic>? oldData, Map<String, dynamic> newData) {
      if (oldData == null) return true;
      if (oldData.length != newData.length) return true;

      for (final key in oldData.keys) {
        if (!newData.containsKey(key)) return true;

        final oldUser = Map<String, dynamic>.from(oldData[key] as Map<String, dynamic>);
        final newUser = Map<String, dynamic>.from(newData[key] as Map<String, dynamic>);

        // Remove lastModifiedDate from comparison
        oldUser.remove('lastModifiedDate');
        newUser.remove('lastModifiedDate');

        // Compare specific fields
        if (oldUser['fname'] != newUser['fname'] ||
            oldUser['lname'] != newUser['lname'] ||
            oldUser['groupCode'] != newUser['groupCode'] ||
            oldUser['phone'] != newUser['phone'] ||
            oldUser['parentPhone'] != newUser['parentPhone'] ||
            oldUser['notes'] != newUser['notes']) {
          print('Changes detected for user $key:');
          print('Old data: $oldUser');
          print('New data: $newUser');
          return true;
        }

        // Compare dates separately as they need special handling
        final oldDate = oldUser['lastPaymentDate'];
        final newDate = newUser['lastPaymentDate'];
        if ((oldDate == null && newDate != null) ||
            (oldDate != null && newDate == null) ||
            (oldDate != null && newDate != null && !_datesAreEqual(oldDate, newDate))) {
          print('Date change detected for user $key');
          return true;
        }
      }
      return false;
    }

    bool _datesAreEqual(Timestamp date1, Timestamp date2) {
      final d1 = date1.toDate();
      final d2 = date2.toDate();
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    }
    Future<Map<String, dynamic>> _parseExcelData(Excel excel) async {
      Map<String, dynamic> data = {};
      try {
        final usersSheet = excel['المستخدمون'];
        print('Parsing Excel sheet: المستخدمون');

        if (usersSheet != null && usersSheet.rows.length > 1) {
          for (var i = 1; i < usersSheet.rows.length; i++) {
            final row = usersSheet.rows[i];

            // Enhanced validation for user ID
            if (row.length > 2 && row[2]?.value != null) {
              String? userId = row[2]!.value.toString().trim();

              // Skip invalid or empty IDs
              if (userId.isEmpty || userId == 'null' || userId == '') {
                print('Skipping invalid ID at row $i');
                continue;
              }

              print('Found valid user ID: $userId');

              // Create user data map with validated data
              Map<String, dynamic> userData = {
                'fname': _validateField(row[0]?.value),
                'lname': _validateField(row[1]?.value),
                'groupCode': _validateField(row[3]?.value),
                'phone': _validateField(row[4]?.value),
                'parentPhone': _validateField(row[5]?.value),
                'notes': _validateField(row[7]?.value),
              };

              // Handle date separately
              final date = _parseDate(row[6]?.value?.toString());
              if (date != null) {
                userData['lastPaymentDate'] = date;
              }

              data[userId] = userData;
              print('Added user data for ID: $userId');
            }
          }
        }
        print('Successfully parsed ${data.length} valid users from Excel');
        return data;
      } catch (e, stackTrace) {
        print('Error parsing Excel data: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    }

    String _validateField(dynamic value) {
      if (value == null) return '';
      String strValue = value.toString().trim();
      return strValue == 'null' ? '' : strValue;
    }

    Future<void> _updateFirebase(Map<String, dynamic> newData, BuildContext context) async {
      try {
        print('Starting Firebase update...');
        final batch = _firestore.batch();
        int updateCount = 0;
        List<String> failedUpdates = [];

        // Process updates in smaller batches
        for (var entry in newData.entries) {
          final userId = entry.key;
          final userData = entry.value;

          // Skip invalid user IDs
          if (userId.isEmpty) {
            print('Skipping empty user ID');
            continue;
          }

          try {
            // Verify document exists before updating
            final docRef = _firestore.collection('users').doc(userId);
            final doc = await docRef.get();

            if (doc.exists) {
              print('Updating user: $userId');
              batch.update(docRef, {
                ...userData,
                'lastModifiedDate': Timestamp.now(),
              });
              updateCount++;
            } else {
              print('User not found: $userId');
              failedUpdates.add(userId);
            }
          } catch (e) {
            print('Error processing user $userId: $e');
            failedUpdates.add(userId);
          }
        }

        if (updateCount > 0) {
          await batch.commit();
          print('Successfully updated $updateCount users');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تحديث $updateCount مستخدمين')),
          );
        }

        if (failedUpdates.isNotEmpty) {
          print('Failed to update users: ${failedUpdates.join(", ")}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تحديث ${failedUpdates.length} مستخدمين')),
          );
        }

      } catch (e, stackTrace) {
        print('Error updating Firebase: $e');
        print('Stack trace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحديث: $e')),
        );
      }
    }




    Timestamp? _parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        final parts = dateStr.split('-');
        if (parts.length != 3) return null;

        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);

        return Timestamp.fromDate(DateTime(year, month, day));
      } catch (e) {
        print('Error parsing date "$dateStr": $e');
        return null;
      }
    }

  }







class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final logger = Logger();
  String? lastScannedCode;
  DateTime? lastScanTime;
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _testController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _barcodeController.dispose();
    _testController.dispose();
    super.dispose();
  }

  Future<void> handleBarcodeScanned(String scannedUid, BuildContext context) async {
    if (_isProcessing) return;

    if (lastScannedCode == scannedUid &&
        lastScanTime != null &&
        DateTime.now().difference(lastScanTime!) < const Duration(seconds: 3)) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      lastScannedCode = scannedUid;
      lastScanTime = DateTime.now();

      logger.d('Starting handleBarcodeScanned with UID: $scannedUid');
      final firestore = FirebaseFirestore.instance;

      final studentDoc = await firestore.collection('users').doc(scannedUid).get();
      if (!studentDoc.exists) {
        throw Exception('Student not found');
      }

      final studentData = studentDoc.data()!;
      final String studentName = '${studentData['fname']} ${studentData['lname']}';
      final List<String> deviceTokens = List<String>.from(studentData['deviceToken'] ?? []);

      final DateTime now = DateTime.now();
      final String dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final existingAttendance = await firestore
          .collection('users')
          .doc(scannedUid)
          .collection('attendance')
          .doc(dateString)
          .get();

      if (existingAttendance.exists) {
        firestore.collection('users').doc(scannedUid).update(
    {
   // 'lastAttendance': now,
    'lastModifiedDate':  Timestamp.now(),
   // 'attendanceDates': FieldValue.arrayUnion([dateString]),
    }
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الحضور مسبقاً اليوم'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      final attendanceData = {
        'studentId': scannedUid,
        'studentName': studentName,
        'timestamp': now,
        'date': dateString,
        'year': now.year,
        'month': now.month,
        'day': now.day,
        'hour': now.hour,
        'minute': now.minute,
      };

      final notificationData = {
        'type': 'attendance',
        'message': 'تم تسجيل حضورك في ${now.hour}:${now.minute}',
        'timestamp': now,
        'read': false,
      };

      final batch = firestore.batch();

      // Set attendance in user's collection
      batch.set(
          firestore
              .collection('users')
              .doc(scannedUid)
              .collection('attendance')
              .doc(dateString),
          attendanceData
      );

      // Set attendance in main attendance collection
      batch.set(
          firestore
              .collection('attendance')
              .doc('$dateString-$scannedUid'),
          attendanceData
      );

      // Add notification
      batch.set(
          firestore
              .collection('users')
              .doc(scannedUid)
              .collection('notifications')
              .doc(),
          notificationData
      );

      // Update user document with attendance info and lastModifiedDate
      batch.update(
          firestore.collection('users').doc(scannedUid),
          {
            'lastAttendance': now,
            'lastModifiedDate':  Timestamp.now(),
            'attendanceDates': FieldValue.arrayUnion([dateString]),
          }
      );

      await batch.commit();

      if (deviceTokens.isNotEmpty) {
        await FCMService.sendNotification(
          title: 'تسجيل الحضور',
          body: 'تم تسجيل حضورك في ${now.hour}:${now.minute}',
          data: {
            'type': 'attendance',
            'date': dateString,
            'timestamp': now.millisecondsSinceEpoch.toString(),
          },
          deviceTokens: deviceTokens,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الحضور بنجاح'),
          duration: Duration(seconds: 1),
        ),
      );

      logger.d('Attendance and lastModifiedDate updated successfully');

    } catch (error) {
      logger.e('Error recording attendance: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تسجيل الحضور'),
          duration: Duration(seconds: 1),
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
      if (kIsWeb) {
        _barcodeController.clear();
        _testController.clear();
        _focusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double scannerSize = screenSize.width * .85;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            'قم بمسح الباركود',
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 20.sp,
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w300,
            ),
          ),
          const Spacer(flex: 1),
          if (kIsWeb) ...[
            // Hidden TextField for physical barcode scanner
            Opacity(
              opacity: 0,
              child: TextField(
                controller: _barcodeController,
                focusNode: _focusNode,
                autofocus: true,
                onChanged: (value) {
                  // Most barcode scanners add a return character
                  if (value.contains('\n') || value.contains('\r')) {
                    final cleanValue = value.replaceAll('\n', '').replaceAll('\r', '');
                    if (cleanValue.isNotEmpty) {
                      handleBarcodeScanned(cleanValue, context);
                    }
                  }
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
            // Visible test input field
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _testController,
                      decoration: const InputDecoration(
                        labelText: 'Test Scanner Input',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          handleBarcodeScanned(value, context);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (_testController.text.isNotEmpty) {
                        handleBarcodeScanned(_testController.text, context);
                      }
                    },
                  ),
                ],
              ),
            ),
            // Visual indicator for web
            Container(
              width: 200.w,
              height: 200.h,
              decoration: BoxDecoration(
                // border: Border.all(
                //   color: const Color(0xFF2196F3),
                //   width: 2.0,
                // ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 48.sp,
                      color: const Color(0xFF2196F3),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'جاهز للمسح بالقارئ',
                      style: TextStyle(
                        color: const Color(0xFF2196F3),
                        fontSize: 16.sp,
                        fontFamily: 'IBM Plex Sans Arabic',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Mobile scanner for Android/iOS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: scannerSize,
                      width: scannerSize,
                      child: MobileScanner(
                        onDetect: (BarcodeCapture capture) async {
                          if (capture.barcodes.isNotEmpty) {
                            final String scannedValue = capture.barcodes[0].rawValue ?? '';
                            if (scannedValue.isNotEmpty) {
                              logger.d('Scanned barcode value: $scannedValue');
                              await handleBarcodeScanned(scannedValue, context);
                            }
                          }
                        },
                      ),
                    ),
                    Container(
                      height: scannerSize,
                      width: scannerSize,
                      decoration: BoxDecoration(
                        // border: Border.all(
                        //   color: const Color(0xFF2196F3),
                        //   width: 2.0,
                        // ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const Spacer(flex: 1),
          Text(
            'تعليمات',
            style: TextStyle(
              color: const Color(0xFF333333),
              fontSize: 14.sp,
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 10.h),
          if (kIsWeb) ...[
            Text(
              '- قم بتوصيل القارئ بالجهاز',
              style: TextStyle(
                color: const Color(0xFFB9B9B9),
                fontSize: 12.sp,
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '- تأكد من تشغيل القارئ',
              style: TextStyle(
                color: const Color(0xFFB9B9B9),
                fontSize: 12.sp,
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w400,
              ),
            ),
          ] else ...[
            Text(
              '- تأكد ان رمز QR يظهر بوضوح.',
              style: TextStyle(
                color: const Color(0xFFB9B9B9),
                fontSize: 12.sp,
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '- اقترب من رمز QR',
              style: TextStyle(
                color: const Color(0xFFB9B9B9),
                fontSize: 12.sp,
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '- تأكد من ان المكان ليس معتم.',
              style: TextStyle(
                color: const Color(0xFFB9B9B9),
                fontSize: 12.sp,
                fontFamily: 'IBM Plex Sans Arabic',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
// No need for custom painter anymore since we're using a simple border

class QRScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double scanAreaHeight = scanAreaSize;

    final Rect scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaHeight,
    );

    // Draw semi-transparent overlay
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanRect);

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw scanner frame
    final Paint scannerFramePaint = Paint()
      ..color = const Color(0xFF00CE39)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw corners
    final double cornerSize = 20;

    // Top left corner
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft + Offset(cornerSize, 0),
      scannerFramePaint,
    );
    canvas.drawLine(
      scanRect.topLeft,
      scanRect.topLeft + Offset(0, cornerSize),
      scannerFramePaint,
    );

    // Top right corner
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight + Offset(-cornerSize, 0),
      scannerFramePaint,
    );
    canvas.drawLine(
      scanRect.topRight,
      scanRect.topRight + Offset(0, cornerSize),
      scannerFramePaint,
    );

    // Bottom left corner
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft + Offset(cornerSize, 0),
      scannerFramePaint,
    );
    canvas.drawLine(
      scanRect.bottomLeft,
      scanRect.bottomLeft + Offset(0, -cornerSize),
      scannerFramePaint,
    );

    // Bottom right corner
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight + Offset(-cornerSize, 0),
      scannerFramePaint,
    );
    canvas.drawLine(
      scanRect.bottomRight,
      scanRect.bottomRight + Offset(0, -cornerSize),
      scannerFramePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Attendance History Screen
class AttendanceHistoryScreen extends StatelessWidget {
const AttendanceHistoryScreen({Key? key}) : super(key: key);

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('سجل الحضور'),
actions: [
IconButton(
icon: const Icon(Icons.calendar_today),
onPressed: () {
showDatePicker(
context: context,
initialDate: DateTime.now(),
firstDate: DateTime(2020),
lastDate: DateTime.now(),
).then((date) {
// Handle date selection
});
},
),
],
),
body: ListView.builder(
itemCount: 10, // Replace with actual attendance data
itemBuilder: (context, index) {
return ListTile(
title: Text('Student Name'),
subtitle: Text('Attendance Time'),
trailing: const Icon(Icons.check_circle, color: Colors.green),
);
},
),
);
}
}