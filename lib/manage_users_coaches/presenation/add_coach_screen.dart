import 'package:admin_future/registeration/presenation/widget/component.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../../home/presenation/widget/widget/custom_app_bar.dart';
import '../../registeration/business_logic/auth_cubit/sign_up_cubit.dart';
import '../../registeration/business_logic/auth_cubit/sign_up_state.dart';

class AddCoachScreen extends StatefulWidget {
  final bool isCoach;

  const AddCoachScreen({super.key, required this.isCoach});

  @override
  _AddCoachScreenState createState() => _AddCoachScreenState();
}

class _AddCoachScreenState extends State<AddCoachScreen> {
  List<String> selectedTeachers = [];

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
                 //add student text
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
    if (widget.isCoach)
    Padding(
    padding: EdgeInsets.symmetric(
    horizontal: 35.0.w, vertical: 10.0.h),
    child: GestureDetector(
    onTap: () {
    showDialog(
    context: context,
    builder: (BuildContext context) {
    return AlertDialog(
    title: const Text('اختر مدرب'),
    content: TeacherSelectionDialog(
    onSelected: (List<String> selected) {
    setState(() {
    selectedTeachers = selected;
    });
    },
    initialSelected: selectedTeachers,
    ),
    actions: <Widget>[
    TextButton(
    child: const Text('Cancel'),
    onPressed: () {
    Navigator.of(context).pop();
    },
    ),
    TextButton(
    child: const Text('Save'),
    onPressed: () {
    Navigator.of(context).pop();
    },
    ),
    ],
    );
    },
    );
    },
    child: Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
//text to 
    Container(
    width: 280.w,
    height: 48.h,
    padding: EdgeInsets.symmetric(
    horizontal: 16.w, vertical: 12.h),
    clipBehavior: Clip.antiAlias,
    decoration: ShapeDecoration(
    color: const Color(0xFFF6F6F6),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(4)),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Expanded(
        child: SizedBox(
          child: Text(
            widget.isCoach
                ? 'اختر المدرسين'
                : 'اختر الطلاب',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: const Color(0xFF666666),
              fontSize: 16.sp,
              fontFamily: 'IBM Plex Sans Arabic',
              fontWeight: FontWeight.w400,
              height: 0,
            ),
          ),
        ),
      ),

    const Spacer(),
      SizedBox(
        width: 20.w,
        height: 11.30.h,
        child: const Icon(
          Icons.arrow_drop_down,
        ),
      ),

    ],
    ),
    ),
    ],
    ),
    ),
    ),

    if (selectedTeachers.isNotEmpty)
      SizedBox(height: 20.0.h),
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
    mainAxisAlignment:
    MainAxisAlignment.end,
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
                      if (selectedTeachers.isNotEmpty)
    SizedBox(height: 20.0.h),
    SizedBox(height: 20.0.h),
    Padding(
    padding: EdgeInsets.symmetric(horizontal: 35.0.w),
    child: ElevatedButton(
    onPressed: () async {
    if (SignUpCubit.get(context)
        .formKey
        .currentState!
        .validate()) {
    if (widget.isCoach) {
  SignUpCubit.get(context).addUser(
  role: 'coach',
  fName: SignUpCubit.get(context).firstNameController.text,
  lName: SignUpCubit.get(context).lastNameController.text,
  phone: SignUpCubit.get(context).phoneController.text.trim(),
  password: SignUpCubit.get(context).passwordController.text,
  hourlyRate: '30',
  teachers: selectedTeachers,
).then((_) async {
  if (context.read<SignUpCubit>().shouldSendWhatsApp == true
  //&&
  //todo:fix this
  //    state is SignUpSuccessState
  ) {
    await context.read<SignUpCubit>().sendWhatsAppMessage(
      phone: SignUpCubit.get(context).phoneController.text.trim(),
      uId: '23rtgyuhijkljnhgsax',
      name: '${SignUpCubit.get(context).firstNameController.text} ${SignUpCubit.get(context).lastNameController.text}',
    );
  }
});
    } else {
      SignUpCubit.get(context).addTrainee(
        fname: SignUpCubit.get(context)
            .firstNameController
            .text,
        lname: SignUpCubit.get(context)
            .lastNameController
            .text,
        phone: SignUpCubit.get(context)
            .phoneController
            .text
            .trim(),
        password: SignUpCubit.get(context)
            .passwordController
            .text,
      );
    }
    }
    if (context.read<SignUpCubit>().shouldSendWhatsApp == true
        //&&
    //    state is SignUpSuccessState
    ) {
      await context.read<SignUpCubit>().sendWhatsAppMessage(
        phone: SignUpCubit.get(context)
            .phoneController
            .text
            .trim(),
        uId: '23rtgyuhijkljnhgsax',
        name: '${SignUpCubit.get(context)
            .firstNameController
            .text} ${SignUpCubit.get(context)
            .lastNameController
            .text}',
      );
    }
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
                            'إرسال معلومات الحساب عبر واتساب',
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
