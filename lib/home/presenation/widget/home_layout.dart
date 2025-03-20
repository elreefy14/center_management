import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../registeration/data/userModel.dart';
import 'dart:async';

// Global navigation key for context access
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  class HomeLayout extends StatefulWidget {
  const HomeLayout({Key? key}) : super(key: key);

    @override
  State<HomeLayout> createState() => _HomeLayoutState();
  }

  class _HomeLayoutState extends State<HomeLayout> {
  late final ExcelFirebaseSync _excelSync;

  @override
  void initState() {
    super.initState();
        _excelSync = ExcelFirebaseSync();
    }

    @override
    void dispose() {
    _excelSync.dispose();
      super.dispose();
    }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> exportExcelFile() async {
    showSnackBar(
        'Excel export is only available on web version. Mobile version coming soon.');
  }

  Future<void> watchExcelChanges() async {
    await _excelSync.watchExcelChanges(context);
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: exportExcelFile,
            tooltip: 'Export Excel File',
          ),
              IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: watchExcelChanges,
            tooltip: 'Watch Excel Changes',
                      ),
                    ],
                  ),
      body: const Center(
        child: Text('Home Layout'),
        ),
      );
    }
  }

  class ExcelFirebaseSync {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    Timer? _watchTimer;

    Future<void> watchExcelChanges(BuildContext context) async {
    // Mobile implementation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
        content: Text(
            'Excel upload is only available on web version. Mobile version coming soon.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void dispose() {
      _watchTimer?.cancel();
  }

  Future<void> downloadExcel(BuildContext context) async {
    // Show message that this feature is only available on web
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
        content: Text(
            'Excel download is only available on web version. Mobile version coming soon.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
      ),
      body: const Center(
        child: Text('QR Scanner functionality will go here'),
      ),
    );
  }
}
