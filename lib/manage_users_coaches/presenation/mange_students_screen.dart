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
//if   List<String>? teachers = prefs.getStringList('teachers'); empty fetch coaches else load coaches

  _cubit.fetchTeachers();
  _cubit.loadCoachesFromPrefs();
  //Future<List<UserModel>> loadCoachesFromPrefs() async {
    //   SharedPreferences prefs = await SharedPreferences.getInstance();
    //   List<String>? teachers = prefs.getStringList('teachers');
    //   if (teachers != null) {
    //     coaches = teachers.map((e) => UserModel(name: e, teachers: [])).toList();
    //   }
    //   return coaches;
    // }
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
          title: const Text('إدارة الطلاب'),
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
              // In your ManageStudentsScreen class, update the ListView.builder section:

              Expanded(
                child: BlocBuilder<ManageStudentsCubit, ManageStudentsState>(
                  builder: (context, state) {
                    if (state is UsersLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is UsersError) {
                      return Center(child: Text(state.message));
                    } else if (state is UsersLoaded || state is UsersLoadingMore) {
                      final users = state is UsersLoaded ? state.users : (state as UsersLoadingMore).currentUsers;

                      return Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            itemCount: users.length + 1, // Add 1 for loading indicator
                            itemBuilder: (context, index) {
                              if (index == users.length) {
                                // Show loading indicator at the bottom if more data is available
                                return state is UsersLoadingMore
                                    ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                                    : const SizedBox.shrink();
                              }

                              final user = users[index];
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
                          ),
                        ],
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              // Add Coach Button
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


  //add manageStudentsCubit

  void _showAddMarksDialog(BuildContext context, UserModel user, ManageStudentsCubit manageStudentsCubit) {
    final marksController = TextEditingController();
    final subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedExamRange = manageStudentsCubit.selectedExamRange;
        String? selectedTeacher = manageStudentsCubit.selectedTeacher;
        var storedCoaches = manageStudentsCubit.coaches;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView( // Add a SingleChildScrollView here to avoid overflow in small screens
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
                  Row(
                    children: [
                      // Marks input field
                      Expanded(
                        flex: 2, // Takes up 2/3 of the space
                        child: SizedBox(
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
                      ),
                      const SizedBox(width: 10), // Add spacing between the fields
                      // Dropdown for exam score range
                      Expanded(
                        flex: 1, // Takes up 1/3 of the space
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Dropdown for teacher selection
                  Container(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, // Add this to prevent overflow
                      value: manageStudentsCubit.selectedTeacher?.isNotEmpty == true
                          ? manageStudentsCubit.selectedTeacher
                          : null,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          manageStudentsCubit.setSelectedTeacher(newValue);
                        }
                      },
                      items: manageStudentsCubit.coaches.map<DropdownMenuItem<String>>((coach) {
                        var coachName = '${coach.fname} ${coach.lname}';
                        return DropdownMenuItem<String>(
                          value: coachName,
                          child: Text(
                            coachName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        hintText: 'المدرس',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
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
                          width: 100,
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
                          width: 100,
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
          ),
        );
      },
    );
  }
  void _showPaymentDialog(BuildContext context, UserModel user) {
    final paymentController = TextEditingController();
    final manageStudentsCubit = ManageStudentsCubit.get(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedTeacher = manageStudentsCubit.selectedTeacher;
        var storedCoaches = manageStudentsCubit.coaches;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
                    'دفع الاشتراك',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
  width: double.infinity,
  child: TextField(
    controller: paymentController,
    decoration: InputDecoration(
      hintText: 'المبلغ المدفوع',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    keyboardType: TextInputType.number,
    textAlign: TextAlign.end,
  ),
),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: manageStudentsCubit.selectedTeacher?.isNotEmpty == true
                          ? manageStudentsCubit.selectedTeacher
                          : null,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          manageStudentsCubit.setSelectedTeacher(newValue);
                        }
                      },
                      items: manageStudentsCubit.coaches.map<DropdownMenuItem<String>>((coach) {
                        var coachName = '${coach.fname} ${coach.lname}';
                        return DropdownMenuItem<String>(
                          value: coachName,
                          child: Text(
                            coachName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        hintText: 'المدرس',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          // Implement payment functionality
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: const Text(
                              'دفع',
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
                          width: 100,
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
          ),
        );
      },
    );
  }
}

