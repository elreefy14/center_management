import 'package:admin_future/registeration/data/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/routes_manager.dart';
import '../../registeration/presenation/widget/widget.dart';
import '../business_logic/manage_students_cubit.dart';

// Manage Coaches screen
class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({Key? key}) : super(key: key);

  @override
  _ManageStudentsScreenState createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ManageStudentsCubit _cubit;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _cubit = ManageStudentsCubit()..fetchUsers(); // Fetch initial users
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the controller
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _cubit.fetchMoreUsers(); // Fetch more users when scrolled to the bottom
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ManageStudentsCubit>(
      create: (context) => _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المدربين'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'رقم الهاتف او الاسم',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                       await _cubit.onSearchSubmitted(_searchController.text.trim(), true);
                      },
                    ),
                  ),
                ),
              ),
              // Table Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المدرب', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('الهاتف', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('درجات', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('الاشتراك', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('المزيد', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // Coach List
              Expanded(
                child: BlocBuilder<ManageStudentsCubit, ManageStudentsState>(
                  builder: (context, state) {
                    if (state is UsersLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state is UsersLoaded) {
                      return ListView.builder(
                        controller: _scrollController, // Assign the scroll controller
                        itemCount: state.users.length,
                        itemBuilder: (context, index) {
                          final user = state.users[index];
                     return Padding(
                       padding:EdgeInsets.symmetric(horizontal: 12.0),
                     child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Show name in multiple lines if it exceeds 14 characters
    Container(
      width: 100, // Adjust width as needed
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: user.name!.length > 14
                ? user.name!.substring(0, user.name!.lastIndexOf(' ', 14)) + '\n'
                : user.name!,
            ),
            if (user.name!.length > 14)
              TextSpan(
                text: user.name!.substring(user.name!.lastIndexOf(' ', 14) + 1),
              ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    // Phone number with fixed width
    GestureDetector(
      onTap: () {
        // Copy phone number to clipboard
        Clipboard.setData(ClipboardData(text: user.phone!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('رقم الهاتف تم نسخه!')),
        );
      },
      child: Text(
        user.phone!, // Coach's phone number
        style: TextStyle(color: Colors.blue),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: () {
        _showAddMarksDialog(context, user, _cubit);
      },
    ),
    IconButton(
      icon: const Icon(Icons.payment),
      onPressed: () {
        _showPaymentDialog(context, user);
      },
    ),
    IconButton(
      icon: const Icon(Icons.info),
      onPressed: () async {
        // Initialize the controllers with user data before navigating
        final manageStudentsCubit = ManageStudentsCubit.get(context);
        await manageStudentsCubit.initControllers(user); // Initialize here
        // Navigate to the edit profile screen
        await Navigator.pushNamed(
          context,
          AppRoutes.editProfile,
          arguments: user as UserModel,
        );
      },
    ),
  ],
),
                     );
                        },
                      );
                    }
                    return Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              // Add Coach Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addCoach,
                      arguments: {
                        'isCoach': true,
                      },
                    );
                  },
                  child: const Text('إضافة مدرب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  //add manageStudentsCubit
  void _showAddMarksDialog(BuildContext context, UserModel user, ManageStudentsCubit manageStudentsCubit) {
    final marksController = TextEditingController();
    final subjectController = TextEditingController();

    manageStudentsCubit.loadPreferences(); // Load preferences when dialog is shown

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider<ManageStudentsCubit>(
          //value: manageStudentsCubit, // Provide the existing cubit instance
          create: (BuildContext context) =>
             BlocBuilder<ManageStudentsCubit, ManageStudentsState>(
              builder: (context, state) {
                String? selectedExamRange = manageStudentsCubit.selectedExamRange;
                String? selectedTeacher = manageStudentsCubit.selectedTeacher;

                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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

                        // Marks input field
                        SizedBox(
                          width: double.infinity,
                          child: TextFormField(
                            controller: marksController,
                            decoration: InputDecoration(
                              hintText: 'الدرجات',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Subject input field
                        SizedBox(
                          width: double.infinity,
                          child: TextFormField(
                            controller: subjectController,
                            decoration: InputDecoration(
                              hintText: 'اسم المادة',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Dropdown for exam score range
                        DropdownButtonFormField<String>(
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Dropdown for teacher selection
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'coach')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            var teachers = snapshot.data!.docs;
                            return DropdownButtonFormField<String>(
                              value: selectedTeacher?.isNotEmpty == true ? selectedTeacher : null,
                              onChanged: (String? newValue) {
                                manageStudentsCubit.setSelectedTeacher(newValue!);
                              },
                              items: teachers.map<DropdownMenuItem<String>>((teacher) {
                                var teacherName = '${teacher['fname']} ${teacher['lname']}';
                                return DropdownMenuItem<String>(
                                  value: teacherName,
                                  child: Text(teacherName),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                hintText: 'اختر المدرس',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                // Handle marks addition
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 130,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'إضافة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 130,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB9B9B9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'إلغاء',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

        );
      },
    );
  }


  void _showPaymentDialog(BuildContext context, UserModel user) {
    final paymentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('دفع الاشتراك'),
          content: TextField(
            controller: paymentController,
            decoration: const InputDecoration(hintText: 'المبلغ المدفوع'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Implement payment functionality
                Navigator.of(context).pop();
              },
              child: const Text('دفع'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }
}

