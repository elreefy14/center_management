import 'package:admin_future/manage_users_coaches/presenation/widgets/user_calander.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/routes_manager.dart';
import '../../core/flutter_flow/flutter_flow_theme.dart';
import '../../home/presenation/widget/widget/custom_app_bar.dart';
import '../business_logic/manage_students_cubit.dart';

class EditUsers extends StatelessWidget {
  final user;
  final isCoach;

  const EditUsers({super.key, required this.user, this.isCoach});
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Builder(
        builder: (context) {
          return Scaffold(
            appBar: const CustomAppBar(text: ''),
            backgroundColor: Colors.white,
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Form(
                  key: ManageStudentsCubit.get(context).formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [

                // User Info Form Fields
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      // First Name Field
                      _buildFormField(
                        context: context,
                        label: 'اسم الاول',
                        controller: ManageStudentsCubit.get(context).firstNameController,
                      ),
                      SizedBox(height: 10.h),

                      // Last Name Field
                      _buildFormField(
                        context: context,
                        label: 'اسم الاخير',
                        controller: ManageStudentsCubit.get(context).lastNameController,
                      ),
                      SizedBox(height: 10.h),

                      // Phone Field
                      _buildFormField(
                        context: context,
                        label: 'رقم الهاتف',
                        controller: ManageStudentsCubit.get(context).phoneController,
                      ),
                      SizedBox(height: 10.h),

                      // Password Field (for coach)
                      if (isCoach) _buildPasswordField(context),

                      // Calendar with reduced height
                      SizedBox(
                        height: screenHeight * 0.6, // Reduced to 40% of screen height
                        child: UserAttendanceCalendar(
                          userId: user.uId ?? '',
                          attendanceDates: user.attendanceDates ?? [
                            "2024-01-15",
                            "2024-02-20",
                            "2024-03-25",
                            "2024-04-10",
                            "2024-05-05",
                            "2024-06-15",
                            "2024-07-20",
                            "2024-08-25",
                            "2024-09-10",
                            "2024-10-05",
                            "2024-11-04",
                            "2024-12-15",
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Marks Card
                          _buildManagementCard(
                            context: context,
                            title: 'الدرجات',
                            icon: Icons.grade_outlined,
                            color: Colors.blue.shade700,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.markManagement,
                                arguments: {
                                  'studentName': '${user.fname} ${user.lname}',
                                  'userId': user.uId,
                                },
                              );
                            },
                          ),

                          // Subscription Card
                          _buildManagementCard(
                            context: context,
                            title: 'الاشتراكات',
                            icon: Icons.card_membership_outlined,
                            color: Colors.green.shade600,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.subscriptionManagement  ,
                                arguments: {
                                  'studentName': '${user.fname} ${user.lname}',
                                  'userId': user.uId,
                                },
                              );
                            },
                          ),
                        ],
                      ),
SizedBox(height: 30.h),

                      // Action Buttons
                      _buildActionButtons(context),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ],
                  ),
                ),
              ),
            ),
          );
        },
      );
  }
  Widget _buildFormField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Readex Pro',
            fontSize: 12,
          ),
        ),
        SizedBox(height: 5.h),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFFF4F4F4),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.blue,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).error,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).error,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Readex Pro',
            fontSize: 10,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'كلمة المرور',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            fontFamily: 'Readex Pro',
            fontSize: 12,
          ),
        ),
        SizedBox(height: 5.h),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: ManageStudentsCubit.get(context).passwordController.text,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ كلمة المرور'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
            Expanded(
              child: TextFormField(
                controller: ManageStudentsCubit.get(context).passwordController,
                readOnly: true,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFFF4F4F4),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Readex Pro',
                  fontSize: 10,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<ManageStudentsCubit, ManageStudentsState>(
          builder: (context, state) {
            return InkWell(
              onTap: () async {
                await ManageStudentsCubit.get(context).updateUserInfo(
                  uid: user.uId,
                  fname: ManageStudentsCubit.get(context).firstNameController.text,
                  lname: ManageStudentsCubit.get(context).lastNameController.text,
                  phone: ManageStudentsCubit.get(context).phoneController.text,
                  hourlyRate: ManageStudentsCubit.get(context).salaryPerHourController.text,
                  numberOfSessions: ManageStudentsCubit.get(context).numberOfSessionsController.text,
                );
              },
              child: state is UpdateUserInfoLoadingState
                  ? const CircularProgressIndicator()
                  : Container(
                height: 50,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'حفظ التعديلات',
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Readex Pro',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 15.h),
        InkWell(
          onTap: () => _showDeleteConfirmation(context),
          child: Text(
            'حذف الحساب',
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Readex Pro',
              color: const Color(0xFFD92D20),
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل تريد حذف الحساب؟'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 100.0,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'لا',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100.0,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                    ),
                    child: const Text(
                      'نعم',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed == true) {
        await ManageStudentsCubit.get(context).deleteUser(uid: user.uId);
        Navigator.of(context).pop();
      }
    });
  }
}
Widget _buildManagementCard({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: MediaQuery.of(context).size.width * 0.43,
      padding: EdgeInsets.symmetric(vertical: 15.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32.h,
            color: color,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Readex Pro',
            ),
          ),
        ],
      ),
    ),
  );
}

// ... [Keep all other existing methods unchanged]

Widget _buildFormField({
  required BuildContext context,
  required String label,
  required TextEditingController controller,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        label,
        style: FlutterFlowTheme.of(context).bodyMedium.override(
          fontFamily: 'Readex Pro',
          fontSize: 12,
        ),
      ),
      SizedBox(height: 5.h),
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Color(0xFFF4F4F4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.blue,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).error,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).error,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        style: FlutterFlowTheme.of(context).bodyMedium.override(
          fontFamily: 'Readex Pro',
          fontSize: 10,
        ),
        textAlign: TextAlign.end,
      ),
    ],
  );
}
