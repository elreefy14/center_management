// Add these imports
import 'dart:async';
import 'package:admin_future/registeration/data/userModel.dart';
import 'package:admin_future/registeration/presenation/widget/widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/routes_manager.dart';
import '../business_logic/manage_students_cubit.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({Key? key}) : super(key: key);
  @override
  _ManageStudentsScreenState createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ManageStudentsCubit _cubit;
  late ScrollController _scrollController;
  Timer? _rollbackTimer;
  String? _lastActionId;
  String? _lastActionType;
  bool _showRollbackButton = false;

  @override
  void initState() {
    super.initState();
    _cubit = ManageStudentsCubit()..fetchUsers();
    _scrollController = ScrollController()..addListener(_onScroll);
    _cubit.fetchTeachers();
    _cubit.loadCoachesFromPrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _rollbackTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _cubit.fetchMoreUsers();
    }
  }


  void _showAddMarksDialog(BuildContext context, UserModel user, ManageStudentsCubit manageStudentsCubit) {
    final marksController = TextEditingController();
    String? selectedExamRange = manageStudentsCubit.selectedExamRange;
    String? selectedTeacher = manageStudentsCubit.selectedTeacher;
    double? pendingMark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SvgPicture.asset(
                            'assets/images/frame23420.svg',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'إضافة درجات',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Marks input field and exam range
                  Row(
                    children: [
                      // Marks input field
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: marksController,
                          decoration: InputDecoration(
                            hintText: 'الدرجات',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Dropdown for exam score range
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: selectedExamRange,
                          onChanged: (String? newValue) {
                            manageStudentsCubit.setSelectedExamRange(newValue!);
                          },
                          items: <String>['10', '20', '30', '40', '50', '60', '70', '80', '90', '100']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            hintText: 'اختر من 10 إلى 100',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Dropdown for teacher selection
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          if (marksController.text.isNotEmpty &&
                              selectedExamRange != null &&
                              selectedTeacher != null) {

                            pendingMark = double.parse(marksController.text);
                            Navigator.pop(context);

                            _startRollbackTimer(
                              'marks',
                                  () async {
                                final markId = await manageStudentsCubit.addMark(
                                  user.uId!,
                                  pendingMark!,
                                  selectedExamRange,
                                  selectedTeacher,
                                );
                                showToast(
                                  state: ToastStates.SUCCESS,
                                  msg: 'تم إضافة الدرجة بنجاح',
                                );
                                return markId;
                              },
                                  () {
                                showToast(
                                  state: ToastStates.SUCCESS,
                                  msg: 'تم إلغاء إضافة الدرجة',
                                );
                              },
                            );
                          } else {
                            showToast(
                              state: ToastStates.WARNING,
                              msg: 'برجاء ملء جميع الحقول',
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                          child: const Align(alignment: Alignment.center, child: Text('إضافة', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFB9B9B9), borderRadius: BorderRadius.circular(8)),
                          child: const Align(alignment: Alignment.center, child: Text('إلغاء', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, UserModel user, ManageStudentsCubit manageStudentsCubit) {
    final paymentController = TextEditingController();
    double? pendingAmount;
    String? pendingTeacher;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('دفع الاشتراك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: paymentController,
                    decoration: InputDecoration(
                      hintText: 'المبلغ المدفوع',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          if (paymentController.text.isNotEmpty && manageStudentsCubit.selectedTeacher != null) {

                            pendingAmount = double.parse(paymentController.text);
                            pendingTeacher = manageStudentsCubit.selectedTeacher;
                            Navigator.pop(context);

                            _startRollbackTimer(
                              'subscription',
                                  () async {
                                final subscriptionId = await manageStudentsCubit.addSubscription(
                                  studentId: user.uId!,
                                  amount: pendingAmount!,
                                  teacherName: pendingTeacher!,
                                );
                                showToast(
                                  state: ToastStates.SUCCESS,
                                  msg: 'تم إضافة الاشتراك بنجاح',
                                );
                                return subscriptionId;
                              },
                                  () {
                                showToast(
                                  state: ToastStates.SUCCESS,
                                  msg: 'تم إلغاء إضافة الاشتراك',
                                );
                              },
                            );
                          } else {
                            showToast(
                              state: ToastStates.WARNING,
                              msg: 'برجاء ملء جميع الحقول',
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                          child: const Align(alignment: Alignment.center, child: Text('دفع', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFB9B9B9), borderRadius: BorderRadius.circular(8)),
                          child: const Align(alignment: Alignment.center, child: Text('إلغاء', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startRollbackTimer(
      String type,
      Future<String> Function() action,
      VoidCallback onRollback,
      ) {
    setState(() {
      _showRollbackButton = true;
      _lastActionType = type;
    });

    _rollbackTimer?.cancel();
    _rollbackTimer = Timer(const Duration(seconds: 5), () async {
      if (!_showRollbackButton) return;

      try {
        final id = await action();
        setState(() {
          _lastActionId = id;
          _showRollbackButton = false;
        });
      } catch (e) {
        showToast(
          state: ToastStates.ERROR,
          msg: type == 'marks' ? 'فشل في إضافة الدرجة' : 'فشل في إضافة الاشتراك',
        );
        setState(() {
          _showRollbackButton = false;
        });
      }
    });
  }

  Future<void> _rollbackAction() async {
    if (_showRollbackButton) {
      _rollbackTimer?.cancel();
      setState(() {
        _showRollbackButton = false;
        _lastActionId = null;
        _lastActionType = null;
      });
      showToast(
        state: ToastStates.SUCCESS,
        msg: _lastActionType == 'marks' ? 'تم إلغاء إضافة الدرجة' : 'تم إلغاء إضافة الاشتراك',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ManageStudentsCubit>(
      create: (context) => _cubit,
      child: Scaffold(
     //   appBar: AppBar(title: const Text('إدارة الطلاب')),
        floatingActionButton: _showRollbackButton
            ?
        //Container(
        //                       width: 50.w,
        //                       height: 50.h,
        //                       decoration: BoxDecoration(
        //                         color: Colors.red,
        //                         borderRadius: BorderRadius.circular(50),
        //                       ),
        //                       child: const Align(
        //                         alignment: AlignmentDirectional(0, 0),
        //                         child: Icon(
        //                           Icons.history_sharp,
        //                           color: Colors.white,
        //                           size: 24,
        //                         ),
        //                       ),
        //                     ),
        //  FloatingActionButton(
        //   onPressed: _rollbackAction,
        //   backgroundColor: Colors.red,
        //   child: const Icon(Icons.undo),
        //   tooltip: 'تراجع عن العملية',
        // )
        InkWell(
          onTap: _rollbackAction,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Align(
              alignment: AlignmentDirectional(0, 0),
              child: Icon(
                Icons.history_sharp,
                color: Colors.white,
                size: 24,
              ),
            )
          )
        )
            : null,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'رقم الهاتف او الاسم',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async => await _cubit.onSearchSubmitted(_searchController.text.trim(), true),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('المدرب', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('درجات', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('الاشتراك', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('المزيد', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<ManageStudentsCubit, ManageStudentsState>(
                  builder: (context, state) {
                    if (state is UsersLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is UsersError) {
                      return Center(child: Text(state.message));
                    } else if (state is UsersLoaded || state is UsersLoadingMore) {
                      final users = state is UsersLoaded ? state.users : (state as UsersLoadingMore).currentUsers;
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(user.name!),
                              GestureDetector(
                                onTap: () => Clipboard.setData(ClipboardData(text: user.phone!)),
                                child: Text(user.phone!, style: const TextStyle(color: Colors.blue)),
                              ),
                              IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddMarksDialog(context, user, _cubit)),
                              IconButton(icon: const Icon(Icons.payment), onPressed: () => _showPaymentDialog(context, user, _cubit)),
                              IconButton(icon: const Icon(Icons.info), onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.editProfile,
                                  arguments: user as UserModel,
                                );
                              }),
                            ],
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addCoach,
                      arguments: {
                        'isCoach': true,
                      },
                    );
                  },
                  child: Container(
                    height: 50.0, // Adjust as needed
                    width: 180.0, // Adjust as needed
                    decoration: BoxDecoration(
                      color: Colors.blue, // Button color
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    child: Align(
                      alignment: Alignment.center, // Align the text to the center
                      child: Text(
                        'إضافة طالب',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white, // Text color
                          fontSize: 14.0, // Text size, adjust as needed
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
