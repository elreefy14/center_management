import 'dart:io';
import 'dart:ui' as ui;
import 'package:barcode_image/barcode_image.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'sign_up_state.dart';
import '../../../core/flutter_flow/form_field_controller.dart';
import '../../data/userModel.dart';
import '../../data/adminModel.dart';
import 'package:admin_future/core/utils/toast_helper.dart';
import 'package:admin_future/registeration/presenation/widget/widget.dart'
    show defaultFormField2, defaultButton, defaultFormField;

//**Collections and Documents:**
// 1. **users**: A collection to store the information of all coaches.   - Document ID: unique coach ID   - Fields: `name`, `level`, `hourly_rate`, `total_hours`, `total_salary`, `current_month_hours`, `current_month_salary`
// 2. **branches**: A collection to store the information of all branches.   - Document ID: unique branch ID   - Fields: `name`, `address`
// 3. **schedules**: A collection to store the information of all schedules.   - Document ID: unique schedule ID   - Fields: `coach_id`, `branch_id`, `start_time`, `end_time`, `date`,  `finished `,
// 4. **attendanceRequests**: A collection to store the attendance requests sent by coaches.   - Document ID: unique attendance request ID   - Fields: `coach_id`, `schedule_id`, `status`(e.g. 'pending', 'accepted', 'rejected')
// 5. **salaryHistory**: A subcollection inside the coach document to store the salary history of each coach.   - Document ID: unique salary history ID (usually just the month and year)   - Fields: `month`, `year`, `total_hours`, `total_salary`

// **Workflow:**
// 1. When a coach logs in, retrieve their information from the `coaches` collection, display their name, training hours, and branches they're assigned to.
// 2. To display the schedules for each coach, query the `schedules` collection with the `coach_id`. Use the `branch_id` to get branch details from the `branches` collection.
// 3. When a coach arrives at their schedule, they create a new document in the `attendanceRequests` collection with the `coach_id`, `schedule_id`, and `status` as 'pending'.
// 4. The admin reviews the attendance requests and updates the `status` field to 'accepted' or 'rejected'.
// 5. Upon receiving an 'accepted' status, calculate the hours worked for that schedule and update the coach's `total_hours`, `total_salary`, `current_month_hours`, and `current_month_salary` in the `coaches` collection.
// 6. At the end of each month, create a new document in the `salaryHistory` subcollection for each coach, storing their `total_hours` and `total_salary` for the current month. After that, reset the `current_month_hours` and `current_month_salary` fields in the `coaches` collection.
// 7. To display the salary history for each coach, query the `salaryHistory` subcollection inside the coach document and show the list containing the current month's total hours and salary, along with all previous months.
// This design allows you to efficiently handle the required functionality while minimizing the number of reads and writes to the Firestore database.

class SignUpCubit extends Cubit<SignUpState> {
  SignUpCubit() : super(InitialState());

  static SignUpCubit get(context) => BlocProvider.of(context);
  // ** New Function: Fetch Coaches **
  Future<void> getTeachers() async {
    emit(GetCoachesLoadingState());
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .get();

      List<String> coaches = querySnapshot.docs
          .map((e) => '${e['fname']} ${e['lname']}')
          .where((name) => name.isNotEmpty)
          .toList();

      emit(GetCoachesSuccessState(coaches: coaches));
    } catch (e) {
      emit(GetCoachesErrorState(error: e.toString()));
    }
  }

  // Selected Teachers List
  List<String> selectedTeachers = [];

  // Update selected teachers list and emit state
  void updateSelectedTeachers(List<String> newSelectedTeachers) {
    selectedTeachers = newSelectedTeachers;
    emit(UpdateSelectedTeachersState(selectedTeachers: selectedTeachers));
  }

  void updateSelectedItems(List<String> newSelectedItems) {
    print('updateSelectedItems');
    print(newSelectedItems[0]);
    print('updateSelectedItems');
    print(newSelectedItems);
    // selectedItems = newSelectedItems[0];
    //add first item newSelectedItems to selectedItems
    selectedItems?.add(newSelectedItems[0]);
    emit(UpdateSelectedItemsState(
      selectedItems: selectedItems,
    ));
    print(selectedItems);
    print(selectedItems!.length);
  }

  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  //hourlyRateController
  final hourlyRateController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final parentPhoneController = TextEditingController();
  final passwordController = TextEditingController();
  final groupCode = TextEditingController();
  List<String>? checkboxGroupValues;
  FormFieldController<List<String>>? checkboxGroupValueController;
  bool showPassword = true;
  void changePasswordVisibility() {
    showPassword = !showPassword;
    emit(ChangePasswordVisibilityState());
  }

  //
  // ** New Function: Fetch Coaches **
  Future<void> getCoaches() async {
    emit(GetCoachesLoadingState());
    try {
      print('Fetching coaches from Firestore...');

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .get();

      print(
          'Query completed. Number of documents found: ${querySnapshot.docs.length}');

      querySnapshot.docs.forEach((doc) {
        print('Document data: ${doc.data()}'); // Printing raw document data
      });

      // Use explicit casting and handle nullable values
      List<String> coaches = querySnapshot.docs
          .map((e) {
            print('Parsing document: ${e.id}'); // Print document id
            UserModel user =
                UserModel.fromJson(e.data() as Map<String, dynamic>);
            print('Parsed user name: ${user.name}'); // Print parsed user name
            return user.name ?? '';
          })
          .where((name) => name.isNotEmpty) // Filter out any empty names
          .toList();

      print('List of coaches: $coaches');

      emit(GetCoachesSuccessState(coaches: coaches));
      print('GetCoachesSuccessState emitted with coaches list.');
    } catch (e) {
      print('Error fetching coaches: $e');
      emit(GetCoachesErrorState(error: e.toString()));
    }
  }

//sign out
  Future<void> signOut() async {
    //emit(SignOutLoadingState());
    await FirebaseAuth.instance.signOut().then((value) {
      // emit(SignOutSuccessState());
    }).catchError((error) {
      //  emit(SignOutErrorState());
    });
  }
//function to check if email and password are in firebase

//make function yo update new password in firebase
  Future<void> updatePassword({
    required String password,
  }) async {
    emit(UpdatePasswordLoadingState());
    FirebaseAuth.instance.currentUser!.updatePassword(password).then((value) {
      emit(UpdatePasswordSuccessState());
    }).catchError((error) {
      String? errorMessage;
      switch (error.code) {
        case "weak-password":
          if (kDebugMode) {
            print(errorMessage);
            errorMessage = 'The password provided is too weak.';
          }
          break;
        case "email-already-in-use":
          if (kDebugMode) {
            print(errorMessage);
            errorMessage = 'The account already exists for that email.';
          }
          break;
        case "invalid-email":
          if (kDebugMode) {
            print(errorMessage);
            errorMessage = 'The email address is badly formatted.';
          }
          break;
        case "operation-not-allowed":
          if (kDebugMode) {
            print(errorMessage);
            errorMessage = 'Email/password accounts are not enabled.';
          }
          break;
        default:
          if (kDebugMode) {
            errorMessage = 'The error is $error';
            print(errorMessage);
          }
      }
      emit(UpdatePasswordErrorState(
        error: errorMessage,
      ));
    });
  }

  Future<void> importStudentsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          // Skip header row
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.length >= 5) {
              // Make sure row has all required fields
              String studentCodeFromExcel = row[0]?.value?.toString() ?? '';
              String studentName = row[1]?.value?.toString() ?? '';
              String parentPhone = row[2]?.value?.toString() ?? '';
              String studentPhone = row[3]?.value?.toString() ?? '';
              String paymentNote = row[4]?.value?.toString() ?? '';

              // Split name into first and last name
              List<String> nameParts = studentName.split(' ');
              String firstName = nameParts.first;
              String lastName =
                  nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

              await addUser(
                role: 'user',
                fName: firstName,
                lName: lastName,
                phone: studentPhone,
                password: '123456', // Default password
                hourlyRate: '30', // Default rate
                teachers: [],
                lastPaymentNote: paymentNote,
                parentPhone: parentPhone,
                studentCode: studentCodeFromExcel,
              );
            }
          }
        }
        emit(ImportSuccessState());
      }
    } catch (e) {
      emit(ImportErrorState(e: e.toString()));
    }
  }

  Future<String?> addUser({
    required String lName,
    required String fName,
    required String phone,
    required String password,
    String role = 'user',
    String? hourlyRate,
    required List<String> teachers,
    required String lastPaymentNote,
    required String parentPhone,
    String? studentCode,
    String? groupCode,
  }) async {
    final logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
      ),
    );

    logger.i('Starting addUser process for: $fName $lName');
    logger.d(
        'Initial parameters - Phone: $phone, Role: $role, StudentCode: $studentCode');

    emit(SignUpLoadingState());
    try {
      if (password.isEmpty) {
        password = '123456';
        logger.d('Empty password provided, using default: 123456');
      }

      // Phone number processing
      logger.d('Original phone number: $phone');
      if (phone.startsWith('٠١')) {
        phone = phone
            .replaceAll('٠', '0')
            .replaceAll('١', '1')
            .replaceAll('٢', '2')
            .replaceAll('٣', '3')
            .replaceAll('٤', '4')
            .replaceAll('٥', '5')
            .replaceAll('٦', '6')
            .replaceAll('٧', '7')
            .replaceAll('٨', '8')
            .replaceAll('٩', '9');
        logger.d('Converted Arabic numerals in phone number: $phone');
      }
      phone = phone.replaceAll(' ', '');
      if (phone.startsWith('+2')) {
        phone = phone.substring(2);
        logger.d('Removed country code from phone: $phone');
      }

      bool isConnect = await checkInternetConnectivity();
      logger.d('Internet connection status: $isConnect');

      // if (!isConnect) {
      //   if (role == 'coach') {
      //     logger.w('Attempted to register coach without internet connection');
      //     emit(SignUpErrorState(error: 'لا يمكنك التسجيل كمدرب بدون انترنت'));
      //     showToast(msg: 'لا يمكنك التسجيل كمدرب بدون انترنت', state: ToastStates.ERROR);
      //     return null;
      //   }
      //   String uId = (studentCode != null && studentCode.isNotEmpty) ? studentCode : const Uuid().v4();
      //   logger.i('Created offline user with ID: $uId');
      //   showToast(msg: 'تم التسجيل بنجاح', state: ToastStates.SUCCESS);
      //   _clearControllers();
      //   emit(SignUpSuccessState(uId));
      //   return uId;
      // }

      logger.d('Getting admin credentials');
      String? adminEmail = FirebaseAuth.instance.currentUser!.email;
      String adminUid = FirebaseAuth.instance.currentUser!.uid;
      logger.d('Admin UID: $adminUid');

      logger.d('Signing out current user');
      await FirebaseAuth.instance.signOut();

      // Check existing student code
      if (studentCode != null && studentCode.isNotEmpty) {
        logger.d('Checking if student code exists: $studentCode');
        final existingDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentCode)
            .get();

        if (existingDoc.exists) {
          logger.w('Student code already exists: $studentCode');
          throw FirebaseAuthException(
              code: 'student-code-exists',
              message: 'A user with this student code already exists');
        }
      }

      logger.d('Creating new user authentication');
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: '$phone@placeholder.com', password: password);
      logger.i('Created auth user with ID: ${userCredential.user!.uid}');

      final String newUid = (studentCode != null && studentCode.isNotEmpty)
          ? studentCode
          : userCredential.user!.uid;
      logger.d('Using ID for Firestore document: $newUid');

      if (studentCode != null && studentCode.isNotEmpty) {
        logger.d('Student code provided, recreating user with custom ID');
        await userCredential.user?.delete();
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: '$phone@placeholder.com', password: password);
      }

      logger.d('Creating UserModel');
      UserModel model = UserModel(
        role: 'user',
        hourlyRate: int.parse(hourlyRate ?? '30'),
        totalHours: 0,
        totalSalary: 0,
        currentMonthHours: 0,
        currentMonthSalary: 0,
        name: '$fName $lName',
        uId: newUid,
        lname: lName,
        fname: fName,
        token: '',
        phone: phone,
        parentPhone: parentPhone,
        pid: adminUid,
        numberOfSessions: 0,
        date: Timestamp.now(),
        lastPaymentDate: Timestamp.now(),
        lastModifiedDate: Timestamp.now(),
        lastPaymentNote: lastPaymentNote,
        branches: [],
        password: password,
        teachers: teachers,
        groupCode: groupCode ?? '',
      );

      logger.d('Saving user to Firestore');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUid)
          .set(model.toJson());

      logger.d('Getting admin document for re-authentication');
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminUid)
          .get();

      final adminPhone = adminDoc.data()?['phone'];
      logger.d('Re-authenticating admin');
      final adminPassword = adminDoc.data()?['password'];

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: '$adminPhone@placeholder.com',
        password: adminPassword!,
      );
      logger.i('Admin re-authenticated successfully');

      _clearControllers();
      showToast(msg: 'تم التسجيل بنجاح', state: ToastStates.SUCCESS);
      emit(SignUpSuccessState(newUid));
      logger.i('User registration completed successfully. UID: $newUid');
      return newUid;
    } catch (error) {
      String? errorMessage;
      logger.e('Error in addUser: $error');

      if (error is FirebaseAuthException) {
        logger.e('FirebaseAuthException code: ${error.code}');
        switch (error.code) {
          case "email-already-in-use":
            errorMessage = 'The account already exists for that email.';
            break;
          case "invalid-email":
            errorMessage = 'The email address is badly formatted.';
            break;
          case "user-not-found":
            errorMessage = 'No user found for that email.';
            break;
          case "wrong-password":
            errorMessage = 'Wrong password provided for that user.';
            break;
          case "student-code-exists":
            errorMessage = 'A user with this student code already exists.';
            break;
          default:
            errorMessage = 'The error is $error';
        }
      } else {
        errorMessage = 'An unexpected error occurred';
      }

      logger.e('Error message: $errorMessage');
      emit(SignUpErrorState(error: errorMessage));
      showToast(msg: errorMessage, state: ToastStates.ERROR);
      return null;
    }
  }

  void _clearControllers() {
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    passwordController.clear();
    hourlyRateController.clear();
  }

  bool shouldSendWhatsApp = false;

  Future<void> sendWhatsAppMessage({
    required String phone,
    required String uId,
    required String name,
  }) async {
    try {
      print(
          'sendWhatsAppMessage called with phone: $phone, uId: $uId, name: $name');

      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();
      final barcodeFile = File('${tempDir.path}/barcode.png');

      // Create barcode widget for rendering
      final barcodeWidget = RepaintBoundary(
        child: Container(
          color: Colors.white,
          width: 300,
          height: 100,
          child: BarcodeWidget(
            barcode: Barcode.code128(),
            data: uId,
            width: 300,
            height: 100,
            color: Colors.black,
          ),
        ),
      );

      // Get the RenderRepaintBoundary
      final RenderRepaintBoundary boundary = RenderRepaintBoundary();
      //final BuildContext? context = barcodeWidget.key?.currentContext;

      // Build the widget
      final PipelineOwner pipelineOwner = PipelineOwner();
      final BuildOwner buildOwner = BuildOwner();

      final Element element = barcodeWidget.createElement();
      buildOwner.buildScope(element);
      buildOwner.finalizeTree();
      pipelineOwner.rootNode = boundary;
      boundary.attach(pipelineOwner);
      boundary.layout(BoxConstraints.tight(const Size(300, 100)));

      // Paint it
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to generate barcode image');
      }

      // Save the barcode image
      await barcodeFile.writeAsBytes(byteData.buffer.asUint8List());
      print('Barcode generated and saved to ${barcodeFile.path}');

      // Prepare WhatsApp message
      final message = 'مرحباً $name!\n'
          'معرف حسابك هو: $uId\n'
          'يرجى الاحتفاظ بهذه المعلومات للرجوع إليها لاحقاً.';

      // Share message and barcode image
      final xFile = XFile(barcodeFile.path);
      await Share.shareXFiles(
        [xFile],
        text: message,
        subject: 'معرف الحساب',
      );
      print('WhatsApp message sent with barcode image');
    } catch (e) {
      print('Error in sendWhatsAppMessage: $e');
      rethrow;
    }
  }

// Alternative implementation using BuildContext if you need to use QrImageView
  Future<void> sendWhatsAppMessageWithContext(
    BuildContext context, {
    required String phone,
    required String uId,
    required String name,
  }) async {
    try {
      print(
          'sendWhatsAppMessage called with phone: $phone, uId: $uId, name: $name');

      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();
      final barcodeFile = File('${tempDir.path}/barcode.png');

      // Create a GlobalKey to get the QR image
      final qrKey = GlobalKey();

      // Create the QR widget
      final qrWidget = RepaintBoundary(
        key: qrKey,
        child: Container(
          color: Colors.white,
          child: QrImageView(
            data: uId,
            version: QrVersions.auto,
            size: 200.0,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
        ),
      );

      // Create an overlay to render the widget
      final overlay = OverlayEntry(
        builder: (context) => Positioned(
          left: -1000,
          top: -1000,
          child: qrWidget,
        ),
      );

      // Add the overlay and wait for the widget to be rendered
      Overlay.of(context).insert(overlay);
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture the image
      final RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Remove the overlay
      overlay.remove();

      if (byteData == null) {
        throw Exception('Failed to generate QR code image');
      }

      // Save the QR code image
      await barcodeFile.writeAsBytes(byteData.buffer.asUint8List());
      print('QR code generated and saved to ${barcodeFile.path}');

      // Prepare WhatsApp message
      final message = 'مرحباً $name!\n'
          'معرف حسابك هو: $uId\n'
          'يرجى الاحتفاظ بهذه المعلومات للرجوع إليها لاحقاً.';

      // Create an XFile object for sharing
      final xFile = XFile(barcodeFile.path);

      // Share message and QR code image via WhatsApp
      await Share.shareXFiles(
        [xFile],
        text: message,
        subject: 'معرف الحساب',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );
      print('WhatsApp message sent with QR code image');
    } catch (e) {
      print('Error in sendWhatsAppMessage: $e');
      rethrow;
    }
  }

  void createUser({
    //password
    bool isUser = false,
    String? paasword,
    String? role,
    required String? uId,
    required String? phone,
    required String? fname,
    required String? lname,
    //branches list
    List<String>? branches,
    int? hourlyRate,
  }) {
    emit(CreateUserLoadingState());
    if (isUser) {
      UserModel model = UserModel(
        role: role,
        hourlyRate: hourlyRate ?? 30,
        totalHours: 0,
        totalSalary: 0,
        currentMonthHours: 0,
        currentMonthSalary: 0,
        name: fname! + ' ' + lname!,
        uId: uId,
        lname: lname,
        fname: fname,
        token: '',
        phone: phone,
        pid: FirebaseAuth.instance.currentUser!.uid,
        numberOfSessions: 0,
        date: Timestamp.now(),
        branches: branches ?? [],
        teachers: [],
      );

      saveUserToContactList(
        name: fname + ' ' + lname,
        phoneNumber: phone!,
      );
      FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .set(model.toJson())
          .then((value) {
        //save user to conatct list in the device

        emit(CreateUserSuccessState(uId!));
      }).catchError((error) {
        print(error.toString());
        emit(CreateUserErrorState());
      });
    } else {
      AdminModel model = AdminModel(
        password: paasword,
        branches: branches,
        lname: lname,
        fname: fname,
        date: Timestamp.now(),
        token: '',
        totalMoneyearned: 0,
        totalMoneySpentOnCoaches: 0,
        Salary: 0,
        phone: phone,
        pId: uId,
      );
      FirebaseFirestore.instance
          .collection('admins')
          .doc(uId)
          .set(model.toMap())
          .then((value) {
        emit(CreateUserSuccessState(uId!));
      }).catchError((error) {
        emit(CreateUserErrorState());
      });
    }
  }

  Future<void> addTrainee({
    required String lname,
    required String fname,
    required String phone,
    required String password,
    String? hourlyRate,
  }) async {
    emit(SignUpLoadingState());
    String uId = Uuid().v4();

    //     //if password is empty
    if (password.isEmpty) {
      password = '123456';
    }
    saveUserToContactList(name: fname + ' ' + lname, phoneNumber: phone);
    //if phone number is arabic number start with ٠١ turn it into english number
    if (phone.startsWith('٠١')) {
      phone = phone.replaceAll('٠', '0');
      phone = phone.replaceAll('١', '1');
      phone = phone.replaceAll('٢', '2');
      phone = phone.replaceAll('٣', '3');
      phone = phone.replaceAll('٤', '4');
      phone = phone.replaceAll('٥', '5');
      phone = phone.replaceAll('٦', '6');
      phone = phone.replaceAll('٧', '7');
      phone = phone.replaceAll('٨', '8');
      phone = phone.replaceAll('٩', '9');
    }
    phone = phone.replaceAll(' ', '');
    if (phone.startsWith('+2')) {
      phone = phone.substring(2);
      //delete any spaces
    }
    UserModel model = UserModel(
      teachers: [],
      role: 'user',
      hourlyRate: int.parse(hourlyRate ?? '30') ?? 30,
      totalHours: 0,
      totalSalary: 0,
      currentMonthHours: 0,
      currentMonthSalary: 0,
      name: fname! + ' ' + lname!,
      uId: uId,
      lname: lname,
      fname: fname,
      token: '',
      phone: phone,
      pid: FirebaseAuth.instance.currentUser!.uid,
      numberOfSessions: 0,
      date: Timestamp.now(),
      branches: [],
    );

    // saveUserToContactList(
    //   name: fname + ' ' + lname,
    //   phoneNumber: phone!,
    // );
    WriteBatch batch = FirebaseFirestore.instance.batch();
    batch.set(
        FirebaseFirestore.instance
            .collection('admins')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('dates')
            .doc(
                '${DateTime.now().month.toString()}-${DateTime.now().year.toString()}'),
        {
          'setFlag': true,
        },
        SetOptions(merge: true));
    batch.update(
      FirebaseFirestore.instance
          .collection('admins')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('dates')
          .doc(
              '${DateTime.now().month.toString()}-${DateTime.now().year.toString()}'),
      {
        'numberOfNewMembers': FieldValue.increment(1),
      },
    );

    //
    // FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(uId)
    //     .set(model.toMap());//use batch
    batch.set(
      FirebaseFirestore.instance.collection('users').doc(uId),
      model.toJson(),
    );
    batch.commit();
    showToast(
      msg: 'تم التسجيل بنجاح',
      state: ToastStates.SUCCESS,
    );
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    passwordController.clear();
    hourlyRateController.clear();
    //save user to conatct list in the device
    emit(CreateUserSuccessState(uId!));
  }

  Future<void> addCoach({
    required String lname,
    required String fname,
    required String phone,
    required String password,
    String? hourlyRate,
  }) async {
    emit(SignUpLoadingState());
    String uId = Uuid().v4();

    //     //if password is empty
    if (password.isEmpty) {
      password = '123456';
    }
    saveUserToContactList(name: fname + ' ' + lname, phoneNumber: phone);
    //if phone number is arabic number start with ٠١ turn it into english number
    if (phone.startsWith('٠١')) {
      phone = phone.replaceAll('٠', '0');
      phone = phone.replaceAll('١', '1');
      phone = phone.replaceAll('٢', '2');
      phone = phone.replaceAll('٣', '3');
      phone = phone.replaceAll('٤', '4');
      phone = phone.replaceAll('٥', '5');
      phone = phone.replaceAll('٦', '6');
      phone = phone.replaceAll('٧', '7');
      phone = phone.replaceAll('٨', '8');
      phone = phone.replaceAll('٩', '9');
    }
    phone = phone.replaceAll(' ', '');
    if (phone.startsWith('+2')) {
      phone = phone.substring(2);
      //delete any spaces
    }
    //save current email and uid
    String? adminEmail = FirebaseAuth.instance.currentUser!.email;
    String? adminUid = FirebaseAuth.instance.currentUser!.uid;
    //get phone and password from collection admins .dcc admin uid
    //then save them in varaible which will be used now

    //debug
    print('\n\nadminemail' + adminEmail! ?? '');
    print('\n\nadmin uid' + adminUid! ?? '');
    //sign out
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: '$phone@placeholder.com', password: password);

    String? coachEmail = FirebaseAuth.instance.currentUser!.email;
    String? coachUid = FirebaseAuth.instance.currentUser!.uid;
    print('\n\coachEmail' + coachEmail! ?? '');
    print('\n\coachUid uid' + coachUid! ?? '');

    ///
    UserModel model = UserModel(
      teachers: [],
      role: 'coach',
      hourlyRate: int.parse(hourlyRate ?? '30') ?? 30,
      totalHours: 0,
      totalSalary: 0,
      currentMonthHours: 0,
      currentMonthSalary: 0,
      name: fname! + ' ' + lname!,
      uId: uId,
      lname: lname,
      fname: fname,
      token: '',
      phone: phone,
      pid: FirebaseAuth.instance.currentUser!.uid,
      numberOfSessions: 0,
      date: Timestamp.now(),
      branches: [],
    );

    // saveUserToContactList(
    //   name: fname + ' ' + lname,
    //   phoneNumber: phone!,
    // );
    FirebaseFirestore.instance.collection('users').doc(uId).set(model.toJson());
    showToast(
      msg: 'تم التسجيل بنجاح',
      state: ToastStates.SUCCESS,
    );
    firstNameController.clear();
    lastNameController.clear();
    phoneController.clear();
    passwordController.clear();
    hourlyRateController.clear();
    //save user to conatct list in the device
    emit(CreateUserSuccessState(uId!));
  }

  Future<void> signUp({
    required String lName,
    required String fName,
    required String phone,
    required String password,
  }) async {
    emit(SignUpLoadingState());
    FirebaseAuth.instance
        .createUserWithEmailAndPassword(
            email: '$phone@placeholder.com', password: password)
        .then((value) {
      print(value.user!.uid);
      createUser(
        branches: selectedItems,
        uId: value.user!.uid,
        phone: phone,
        fname: fName,
        lname: lName,
      );
      emit(SignUpSuccessState(value.user!.uid));
    }).catchError((error) {
      String? errorMessage;
      switch (error.code) {
        //case user already exists
        case "email-already-in-use":
          if (kDebugMode) {
            print(errorMessage);
            errorMessage = 'The account already exists for that email.';
          }
          break;
        case "invalid-email":
          if (kDebugMode) {
            print(errorMessage);
            errorMessage = 'The email address is badly formatted.';
          }
          break;
        case "user-not-found":
          if (kDebugMode) {
            print(errorMessage);
            errorMessage = 'No user found for that email.';
          }
          break;
        case "wrong-password":
          if (kDebugMode) {
            print(errorMessage);
            errorMessage = 'Wrong password provided for that user.';
          }
          break;
        default:
          if (kDebugMode) {
            errorMessage = 'The error is $error';
            print(errorMessage);
          }
      }
      emit(SignUpErrorState(
        error: errorMessage,
      ));
    });
  }

  //selected items
  List<String>? selectedItems;
  void add(String itemValue) {
    selectedItems ??= [];
    print('add');
    print(itemValue);
    print(itemValue.toString());
    selectedItems?.add(itemValue.toString());

    emit(UpdateSelectedItemsState(
      selectedItems: selectedItems,
    ));
    print(selectedItems);
  }

  void remove(String itemValue) {
    selectedItems ??= [];
    selectedItems?.remove(itemValue.toString());
    emit(UpdateSelectedItemsState(
      selectedItems: selectedItems,
    ));
    print(selectedItems);
  }

  void itemChange(String itemValue, bool isSelected, BuildContext context) {
    //final List<String> updatedSelection = List.from(
    //   SignUpCubit.get(context).selectedItems ?? []);

    if (isSelected) {
      add(itemValue);
      // updatedSelection.add(itemValue);
    } else {
      remove(itemValue);
      //  updatedSelection.remove(itemValue);
    }

    //  onSelectionChanged(updatedSelection);
  }

  // final List<String> items = ['Flutter',
//         'Node.js',
//         'React Native',
//         'Java',
//         'Docker',
//         'MySQL'
//       ];
  //add list of branches names to branches collection in firebase
  Future<void> addBranches() async {
    emit(AddBranchesLoadingState());
    List<String> branches = [
      'المعادي',
      'المهندسين',
      'المقطم',
      'المنصورة',
      'المنيا',
      'النزهة',
    ];
    branches.forEach((element) {
      FirebaseFirestore.instance.collection('branches').add({
        'name': element,
      }).then((value) {
        emit(AddBranchesSuccessState());
      }).catchError((error) {
        emit(AddBranchesErrorState());
      });
    });
  }

  List<String>? items;
  Future<void> getBranches() async {
    items = [];
    emit(GetBranchesLoadingState());
    FirebaseFirestore.instance.collection('branches').get().then((value) {
      value.docs.forEach((element) {
        items?.add(element['name']);
      });
      emit(GetBranchesSuccessState());
    }).catchError((error) {
      emit(GetBranchesErrorState());
    });
  }

  checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // void saveUserToContactList({required String name, String? phone}) {
  //   //use package contact_service to save user to contact list in the device
  //  print('saveUserToContactList\n\n\n\n\'');
  //   Contact newContact = new Contact(
  //     givenName: name,
  //     phones: [Item(label: "mobile", value: phone)],
  //   );
  //   ContactsService.addContact(newContact);
  //
  // }

  Future<void> saveUserToContactList(
      {required String name, required String phoneNumber}) async {
    // Contact functionality has been removed
    print('Contact saving functionality removed: $name, $phoneNumber');
    return;
  }

  void updateControllers(
      {required String firstName,
      required String lastName,
      required String phone}) {
    firstNameController.text = firstName;
    lastNameController.text = lastName;
    phoneController.text = phone;
    emit(UpdateControllersState());
  }

  // Replace any other contact-related methods with this simpler version
  Future<void> saveContact(String name, String phoneNumber) async {
    // Contact functionality has been removed
    print('Contact saving functionality removed: $name, $phoneNumber');
    return;
  }
}
////////////////
