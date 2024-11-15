
import 'package:admin_future/attendence/presentation/attendence_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../attendence/attendence_cubit.dart';
import '../../../core/excel_exports_service.dart';
import '../../../core/fcm_helper.dart';
import '../../../manage_users_coaches/presenation/add_student_screen.dart';
import '../../../manage_users_coaches/presenation/mange_students_screen.dart';

// Main Layout
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:excel/excel.dart' as excel;
import 'dart:html' as html;
import 'package:excel/excel.dart' as excel;




class HomeLayout extends StatefulWidget {
  @override
  _HomeLayoutState createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int currentIndex = 0;
  final excelExportService = ExcelExportService();
  bool isExporting = false;



  Future<void> exportUsersDataWeb() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final usersSnapshot = await firestore.collection('users').get();

      var excelFile = excel.Excel.createExcel();
      excel.Sheet sheetObject = excelFile['Users'];

      // Add headers using cell values
      final headers = [
        excel.TextCellValue('Name'),
        excel.TextCellValue('Email'),
        excel.TextCellValue('Phone'),
        excel.TextCellValue('Last Attendance'),
        excel.TextCellValue('Total Attendance Days')
      ];
      sheetObject.appendRow(headers);

      // Add data rows
      for (var doc in usersSnapshot.docs) {
        var data = doc.data();
        final rowData = [
          excel.TextCellValue('${data['fname']} ${data['lname']}'),
          excel.TextCellValue(data['email']?.toString() ?? ''),
          excel.TextCellValue(data['phone']?.toString() ?? ''),
          excel.TextCellValue(data['lastAttendance']?.toDate()?.toString() ?? ''),
          excel.TextCellValue((data['attendanceDates'] as List?)?.length?.toString() ?? '0')
        ];
        sheetObject.appendRow(rowData);
      }

      // Style the header row
      final headerStyle = excel.CellStyle(
          bold: true,
         // backgroundColorHex:
        //  fontColorHex: '#FFFFFF',
          horizontalAlign: excel.HorizontalAlign.Center
      );

      // Apply header styles
      for (var i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = headerStyle;
      }

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheetObject.setColumnWidth(i, 20);
      }

      // Convert to bytes and download
      final bytes = excelFile.save();
      if (bytes != null) {
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'users_data.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      print('Export error: $e');
      rethrow;
    }
  }

  final List<Widget> screens = [
    const ManageStudentsScreen(),
     QRScannerScreen(),
    //give provider to the attendance screen
    BlocProvider(
      create: (context) => AttendanceCubit()..loadAttendance(
        //
 // Future<void> loadAttendance(DateTime date, {bool refresh = false})
        DateTime.now(),

      ),
      child:  AttendanceScreen(),
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar:
      //if list of titles is الحضور then show container else show appbar
      currentIndex == 2 || currentIndex == 1
          ? null
          :
      AppBar(
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
                //show toast that can take some time
                const snackBar = SnackBar(
                  content: Text('جاري تصدير البعيانات...'),
                  duration: Duration(seconds: 1),
                );
                setState(() => isExporting = true);
                await excelExportService.exportUsersData();
                setState(() => isExporting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تصدير البيانات بنجاح')),
                );
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
                            color: index == currentIndex ? const Color(0xff2196F3) : Colors.transparent,
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
                        color: index == currentIndex ? const Color(0xffFFFFFF) : Colors.black26,
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
                      color: index == currentIndex ? const Color(0xff2196F3) : Colors.black26,
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

      batch.set(
          firestore
              .collection('users')
              .doc(scannedUid)
              .collection('attendance')
              .doc(dateString),
          attendanceData
      );

      batch.set(
          firestore
              .collection('attendance')
              .doc('$dateString-$scannedUid'),
          attendanceData
      );

      batch.set(
          firestore
              .collection('users')
              .doc(scannedUid)
              .collection('notifications')
              .doc(),
          notificationData
      );

      batch.update(
          firestore.collection('users').doc(scannedUid),
          {
            'lastAttendance': now,
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

      logger.d('Attendance recorded successfully');

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
                border: Border.all(
                  color: const Color(0xFF2196F3),
                  width: 2.0,
                ),
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
                        border: Border.all(
                          color: const Color(0xFF2196F3),
                          width: 2.0,
                        ),
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