
import 'package:admin_future/attendence/presentation/attendence_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logger/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../attendence/attendence_cubit.dart';
import '../../../manage_users_coaches/presenation/add_student_screen.dart';
import '../../../manage_users_coaches/presenation/mange_students_screen.dart';

// Main Layout
import 'package:flutter_svg/flutter_svg.dart';

class HomeLayout extends StatefulWidget {
  @override
  _HomeLayoutState createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int currentIndex = 0;
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


// ... [Previous HomeLayout code remains the same] ...
class QRScannerScreen extends StatelessWidget {
   QRScannerScreen({Key? key}) : super(key: key);


final logger = Logger();

   Future<void> _handleBarcodeScanned(String scannedValue, BuildContext context) async {
     try {
       logger.d('Starting _handleBarcodeScanned with data: $scannedValue');

       // Try to parse the barcode data
       final parsedData = BarcodeData.decode(scannedValue);
       if (parsedData == null) {
         throw Exception('Invalid barcode format');
       }

       logger.d('Parsed data - UID: ${parsedData.uid}, Name: ${parsedData.name}');

       final FirebaseFirestore firestore = FirebaseFirestore.instance;

       // First verify if the student exists
       final studentDoc = await firestore.collection('users').doc(parsedData.uid).get();
       if (!studentDoc.exists) {
         throw Exception('Student not found');
       }

       final WriteBatch batch = firestore.batch();
       final DateTime now = DateTime.now();

       // Get the actual student name from Firestore
       final String studentName = '${studentDoc.get('fname')} ${studentDoc.get('lname')}';

       final Map<String, dynamic> attendanceData = {
         'studentId': parsedData.uid,
         'studentName': studentName, // Use name from Firestore
         'timestamp': now,
         'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
         'year': now.year,
         'month': now.month,
         'day': now.day,
         'hour': now.hour,
         'minute': now.minute,
       };

       logger.d('Attendance data: $attendanceData');

       // Check if attendance already recorded for today
       final existingAttendance = await firestore
           .collection('users')
           .doc(parsedData.uid)
           .collection('attendance')
           .doc('${now.year}-${now.month}-${now.day}')
           .get();

       if (existingAttendance.exists) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('تم تسجيل حضور $studentName مسبقاً اليوم'),
             backgroundColor: Colors.orange,
           ),
         );
         return;
       }

       // Add to student's attendance subcollection
       batch.set(
           firestore
               .collection('users')
               .doc(parsedData.uid)
               .collection('attendance')
               .doc('${now.year}-${now.month}-${now.day}'),
           attendanceData
       );

       // Add to general attendance collection
       batch.set(
           firestore
               .collection('attendance')
               .doc('${now.year}-${now.month}-${now.day}-${parsedData.uid}'),
           attendanceData
       );

       // Update student's attendance summary
       batch.update(
           firestore.collection('users').doc(parsedData.uid),
           {
             'lastAttendance': now,
             'attendanceDates': FieldValue.arrayUnion([attendanceData['date']]),
           }
       );

       await batch.commit();
       logger.d('Attendance recorded successfully');

       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('تم تسجيل حضور $studentName بنجاح'),
           backgroundColor: Colors.green,
         ),
       );
     } catch (error) {
       logger.e('Error recording attendance: $error');
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('حدث خطأ أثناء تسجيل الحضور: ${error.toString()}'),
           backgroundColor: Colors.red,
         ),
       );
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
                            await _handleBarcodeScanned(scannedValue, context);
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
          const Spacer(flex: 1),
          // Instructions
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