import 'dart:convert';

import 'package:admin_future/registeration/presenation/widget/component.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../home/presenation/widget/widget/custom_app_bar.dart';
import '../../registeration/business_logic/auth_cubit/sign_up_cubit.dart';
import '../../registeration/business_logic/auth_cubit/sign_up_state.dart';
class BarcodeData {
  final String uid;
  final String name;

  BarcodeData({required this.uid, required this.name});

  // Simple format: "UID#NAME"
  String encode() => "$uid#$name";

  static BarcodeData? decode(String rawValue) {
    try {
      // First try to split with #
      if (rawValue.contains('#')) {
        final parts = rawValue.split('#');
        if (parts.length == 2) {
          return BarcodeData(uid: parts[0].trim(), name: parts[1].trim());
        }
      }
      // If no #, assume it's just a UID for backward compatibility
      return BarcodeData(uid: rawValue.trim(), name: 'Unknown');
    } catch (e) {
      print('Error decoding barcode data: $e');
      return null;
    }
  }
}


class AddCoachScreen extends StatefulWidget {
  final bool isCoach;

  const AddCoachScreen({super.key, required this.isCoach});

  @override
  _AddCoachScreenState createState() => _AddCoachScreenState();
}

class _AddCoachScreenState extends State<AddCoachScreen> {
  List<String> selectedTeachers = [];

  Future<File> generateBarcodeImage(String uId, String name) async {
    final GlobalKey globalKey = GlobalKey();

    Logger().d('Generating barcode with UID: $uId');

    final barcodeWidget = RepaintBoundary(
      key: globalKey,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BarcodeWidget(
              barcode: Barcode.code128(),
              data: uId,
              width: 300,
              height: 100,
              drawText: true,
            ),
            const SizedBox(height: 10),
            Text(
              'معرف المستخدم: $uId',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'الاسم: $name',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -1000,
        top: -1000,
        child: barcodeWidget,
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    await Future.delayed(const Duration(milliseconds: 100));

    final RenderRepaintBoundary boundary =
    globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    overlayEntry.remove();

    if (byteData == null) {
      throw Exception('Failed to generate barcode image');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/barcode.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    return file;
  }

  Future<void> sendWhatsAppMessageWithBarcode({
    required String phone,
    required String uId,
    required String name,
  }) async {
    try {
      if (kIsWeb) {
        final barcodeImage = await generateBarcodeImage(uId, name);
        final bytes = await barcodeImage.readAsBytes();
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement()
          ..href = url
          ..download = 'barcode_$uId.png'
          ..click();

        html.Url.revokeObjectUrl(url);
        return;
      }

      // Non-web sharing logic
      final barcodeFile = await generateBarcodeImage(uId, name);
      final message = 'مرحباً $name!\n'
          'معرف حسابك هو: $uId\n'
          'يرجى مسح الباركود أدناه للتحقق من هويتك.\n'
          'يرجى الاحتفاظ بهذه المعلومات للرجوع إليها لاحقاً.';

      final xFile = XFile(barcodeFile.path);
      await Share.shareXFiles(
        [xFile],
        text: message,
        subject: 'معلومات الحساب',
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء إرسال الرسالة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Modify the existing onPressed handler in the ElevatedButton
  Future<void> handleRegistration() async {
    if (SignUpCubit.get(context).formKey.currentState!.validate()) {
      String? newUid;
String name = '${SignUpCubit.get(context).firstNameController.text} ${SignUpCubit.get(context).lastNameController.text}';

      newUid = await SignUpCubit.get(context).addUser(
        role: 'user',
        fName: SignUpCubit.get(context).firstNameController.text,
        lName: SignUpCubit.get(context).lastNameController.text,
        phone: SignUpCubit.get(context).phoneController.text.trim(),
        password: SignUpCubit.get(context).passwordController.text,
        groupCode: SignUpCubit.get(context).groupCode.text,
        hourlyRate: '30',
        teachers: [],
        lastPaymentNote: '', // Added empty string as default
        parentPhone: SignUpCubit.get(context).parentPhoneController.text.trim(), // Using parent phone controller
        studentCode: null, // Added null as default

      );

      if (newUid != null && context.read<SignUpCubit>().shouldSendWhatsApp) {
        await sendWhatsAppMessageWithBarcode(
          phone: SignUpCubit.get(context).phoneController.text.trim(),
          uId: newUid,
          name: name,
        );
      }
    }
  }

  Future<void> _generateAndShareBarcode(String studentId, String studentName) async {
    try {
      // Create a GlobalKey to get the barcode widget's render box
      final GlobalKey globalKey = GlobalKey();

      // Create the widget with the global key
      final Widget barcodeWidget = RepaintBoundary(
        key: globalKey,
        child: Container(
          color: Colors.white,
          child: BarcodeWidget(
            barcode: Barcode.code128(),
            data: studentId,
            width: 300,
            height: 100,
            color: Colors.black,
          ),
        ),
      );

      // Create a temporary context to render the widget
      final BuildContext? context = globalKey.currentContext;
      if (context == null) {
        // Create an overlay entry to render the widget
        final overlayEntry = OverlayEntry(
          builder: (context) => barcodeWidget,
        );

        Overlay.of(context!).insert(overlayEntry);
        await Future.delayed(const Duration(milliseconds: 100));

        final RenderRepaintBoundary boundary = globalKey.currentContext!
            .findRenderObject()! as RenderRepaintBoundary;

        final ui.Image image = await boundary.toImage();
        overlayEntry.remove();

        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();

        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/barcode.png').create();
        await file.writeAsBytes(bytes);

        // Share using XFile
        final xFile = XFile(file.path);
        await Share.shareXFiles(
          [xFile],
          text: 'باركود الطالب: $studentName',
          subject: 'Student Barcode',
        );
      }
    } catch (e) {
      print('Error generating or sharing barcode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء مشاركة الباركود'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBarcodeDialog(String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('باركود الطالب: $studentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BarcodeWidget(
              barcode: Barcode.code128(),
              data: studentId,
              width: 300,
              height: 100,
              color: Colors.black,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _generateAndShareBarcode(studentId, studentName),
              icon: const Icon(Icons.share),
              label: const Text('مشاركة الباركود'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(builder: (context, state) {
      return Scaffold(
          backgroundColor: Colors.white,
          appBar: const CustomAppBar(
            text: '',
          ),
          body: ListView(
              children: [
              SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.only(top: 32.0.h),
            child: Center(
              child: Container(
                alignment: Alignment.center,
                child: widget.isCoach
                    ? Text(
                  'اضافة طالب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontSize: 32.sp,
                    fontFamily: 'Montserrat-Arabic',
                    fontWeight: FontWeight.w400,
                    height: 0.03.h,
                  ),
                )
                    : Text(
                  'اضافة متدرب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF333333),
                    fontSize: 32.sp,
                    fontFamily: 'Montserrat-Arabic',
                    fontWeight: FontWeight.w400,
                    height: 0.03.h,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 50.0.h),
          Form(
              key: SignUpCubit.get(context).formKey,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                Padding(
                padding: EdgeInsets.symmetric(horizontal: 35.0.w),
                child: BuildTextFormField2(
                  context: context,
                  'الاسم الاول',
                  SignUpCubit.get(context).firstNameController,
                  TextInputType.name,
                  'ادخل الاسم الاول',
                      (value) {
                    if (value!.isEmpty) {
                      return ' الرجاء ادخال الاسم الاول';
                    }
                    return null;
                  },
                  Icons.person,
                ),
              ),
              SizedBox(height: 20.0.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 35.0.w),
                child: BuildTextFormField2(
                  'الاسم الاخير',
                  SignUpCubit.get(context).lastNameController,
                  TextInputType.name,
                  'ادخل الاسم الاخير',
                      (value) {
                    if (value!.isEmpty) {
                      return 'الرجاء ادخال الاسم الاخير';
                    }
                    return null;
                  },
                  Icons.person,
                ),
              ),     SizedBox(height: 20.0.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 35.0.w),
                child: BuildTextFormField2(
                  'كود المجموعه',
                  SignUpCubit.get(context).groupCode,
                  TextInputType.name,
                  'كود المجموعه',
                      (value) {
                    if (value!.isEmpty) {
                      return 'الرجاء ادخال الاسم الاخير';
                    }
                    return null;
                  },
                  Icons.person,
                ),
              ),
              const SizedBox(height: 20.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 35.0.w),
                child: BuildTextFormField2(
                  'رقم الهاتف',
                  SignUpCubit.get(context).phoneController,
                  TextInputType.phone,
                  'ادخل رقم الهاتف',
                      (value) {
                    if (value!.isEmpty) {
                      return 'الرجاء ادخال رقم الهاتف';
                    }
                    return null;
                  },
                  Icons.phone,
                ),
              ),
                      const SizedBox(height: 20.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 35.0.w),
                child: BuildTextFormField2(
                  'رقم هاتف ولي الامى ',
                  SignUpCubit.get(context).parentPhoneController,
                  TextInputType.phone,
                  'ادخل رقم الهاتف',
                      (value) {
                    if (value!.isEmpty) {
                      return 'الرجاء ادخال رقم الهاتف';
                    }
                    return null;
                  },
                  Icons.phone,
                ),
              ),
              SizedBox(height: 20.0.h),
              if (widget.isCoach)
          Padding(
      padding: EdgeInsets.symmetric(horizontal: 35.0.w),
    child: BuildTextFormField2(
    'كلمة المرور',
    SignUpCubit.get(context).passwordController,
    TextInputType.text,
    'ادخل كلمة المرور',
    (value) {
    if (value!.isEmpty) {
    return 'الرجاء ادخال كلمة المرور';
    } else if (value.length < 6) {
    return 'يجب ادخال كلمة مرور اكثر من ٦ أحرف او ارقام';
    }
    return null;
    },
    Icons.lock,
    context: context,
    ),
    ),
    if (selectedTeachers.isNotEmpty) SizedBox(height: 20.0.h),
    if (selectedTeachers.isNotEmpty)
    Padding(
    padding: EdgeInsets.symmetric(horizontal: 35.0.w),
    child: ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    separatorBuilder: (context, index) => SizedBox(
    height: 15.h,
    ),
    shrinkWrap: true,
    itemCount: selectedTeachers.length,
    itemBuilder: (context, index) {
    var teacher = selectedTeachers[index];
    return Container(
    width: 360.w,
    height: 25.h,
    padding: EdgeInsets.symmetric(horizontal: 15.w),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
    Container(
    width: 25.w,
    height: 25.h,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(),
    child: InkWell(
    onTap: () {
    setState(() {
    selectedTeachers.remove(teacher);
    });
    },
    child: SvgPicture.asset(
    'assets/images/delete-2_svgrepo.com.svg'),
    ),
    ),
    Expanded(
    child: Container(
    height: double.infinity,
    child: Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment:
    CrossAxisAlignment.center,
    children: [
    Text(
    '${index + 1} - $teacher',
    textAlign: TextAlign.right,
    style: TextStyle(
    color: Colors.black,
    fontSize: 14.sp,
    fontFamily: 'Montserrat-Arabic',
    fontWeight: FontWeight.w400,
    height: 0,
    ),
    ),
    ],
    ),
    ),
    ),
    ],
    ),
    );
    },
    ),
    ),
    if (selectedTeachers.isNotEmpty) SizedBox(height: 20.0.h),
    SizedBox(height: 20.0.h),
    Padding(
    padding: EdgeInsets.symmetric(horizontal: 35.0.w),
    child: ElevatedButton(
    onPressed: () async {
      handleRegistration();
    },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2196F3),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 18),
      ),
      child: const Text(
        'تسجيل حساب جديد',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
     ),
    ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 35.0.w),
                        child: CheckboxListTile(
                          value: context.read<SignUpCubit>().shouldSendWhatsApp,
                          onChanged: (value) {
                            setState(() {
                              context.read<SignUpCubit>().shouldSendWhatsApp =
                              value!;
                            });
                          },
                          title: Text(
                            'الحصول علي الصورة',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: 'IBM Plex Sans Arabic',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                    ],
                ),
              ),
          ),
              ],
          ),
      );
    });
  }
}

class TeacherSelectionDialog extends StatefulWidget {
  final List<String> initialSelected;
  final Function(List<String>) onSelected;

  const TeacherSelectionDialog({
    Key? key,
    required this.initialSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  _TeacherSelectionDialogState createState() => _TeacherSelectionDialogState();
}

class _TeacherSelectionDialogState extends State<TeacherSelectionDialog> {
  List<String> selectedTeachers = [];

  @override
  void initState() {
    super.initState();
    selectedTeachers = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        var teachers = snapshot.data!.docs;

        return SizedBox(
          width: 300.0.w,
          height: 300.0.h,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              var teacher = teachers[index];
              var teacherName = '${teacher['fname']} ${teacher['lname']}';

              return CheckboxListTile(
                value: selectedTeachers.contains(teacherName),
                title: Text(teacherName),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedTeachers.add(teacherName);
                    } else {
                      selectedTeachers.remove(teacherName);
                    }
                    widget.onSelected(selectedTeachers);
                  });
                },
              );
            },
          ),
        );
      },
    );
  }
}
// models/mark_model.dart
class MarkModel {
  final String id;
  final double mark;
  final String examRange;
  final String teacherName;
  final String studentId;
  final DateTime timestamp;

  MarkModel({
    required this.id,
    required this.mark,
    required this.examRange,
    required this.teacherName,
    required this.studentId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'mark': mark,
    'examRange': examRange,
    'teacherName': teacherName,
    'studentId': studentId,
    'timestamp': timestamp,
  };

  factory MarkModel.fromJson(Map<String, dynamic> json) => MarkModel(
    id: json['id'],
    mark: json['mark'].toDouble(),
    examRange: json['examRange'],
    teacherName: json['teacherName'],
    studentId: json['studentId'],
    timestamp: (json['timestamp'] as Timestamp).toDate(),
  );
}

// models/subscription_model.dart
class SubscriptionModel {
  final String id;
  final double amount;
  final String teacherName;
  final String studentId;
  final DateTime timestamp;
  final bool active;

  SubscriptionModel({
    required this.id,
    required this.amount,
    required this.teacherName,
    required this.studentId,
    required this.timestamp,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'teacherName': teacherName,
    'studentId': studentId,
    'timestamp': timestamp,
    'active': active,
  };

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => SubscriptionModel(
    id: json['id'],
    amount: json['amount'].toDouble(),
    teacherName: json['teacherName'],
    studentId: json['studentId'],
    timestamp: (json['timestamp'] as Timestamp).toDate(),
    active: json['active'] ?? true,
  );
}