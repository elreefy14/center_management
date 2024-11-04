import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../registeration/data/userModel.dart';
import '../../registeration/presenation/widget/widget.dart';
import '../presenation/add_student_screen.dart';
import '../presenation/mange_students_screen.dart';

part 'manage_students_state.dart';


  class ManageStudentsCubit extends Cubit<ManageStudentsState> {
    ManageStudentsCubit()
        : super(ManageStudentsInitial()); // Set an initial state

    List<UserModel> users = []; // Store the list of users
    DocumentSnapshot? lastDocument; // Store the last fetched document for pagination
    bool isLoadingMore = false; // To manage loading state for pagination
    String? selectedExamRange = '10';
    String? selectedTeacher = '';
    List<UserModel> coaches = [];
    bool hasMoreData = true;


    List<UserModel> searchResults = [];


    bool isSearchMode = false;
    String lastSearchQuery = '';
    Future<String> addMark(String studentId, double mark, String examRange, String teacherName) async {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc();
        final markId = docRef.id;

        final markData = MarkModel(
          id: markId,
          mark: mark,
          examRange: examRange,
          teacherName: teacherName,
          studentId: studentId,
          timestamp: DateTime.now(),
        ).toJson();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection('marks')
            .doc(markId)
            .set(markData);

        return markId;
      } catch (e) {
        throw Exception('Failed to add mark: $e');
      }
    }

    Future<String> addSubscription({
      required String studentId,
      required double amount,
      required String teacherName,
    }) async {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc();
        final subscriptionId = docRef.id;

        final subscriptionData = SubscriptionModel(
          id: subscriptionId,
          amount: amount,
          teacherName: teacherName,
          studentId: studentId,
          timestamp: DateTime.now(),
        ).toJson();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection('subscriptions')
            .doc(subscriptionId)
            .set(subscriptionData);

        return subscriptionId;
      } catch (e) {
        throw Exception('Failed to add subscription: $e');
      }
    }

    Future<void> deleteMark(String markId) async {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc()
            .collection('marks')
            .doc(markId)
            .delete();
      } catch (e) {
        throw Exception('Failed to delete mark: $e');
      }
    }

    Future<void> deleteSubscription(String subscriptionId) async {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc()
            .collection('subscriptions')
            .doc(subscriptionId)
            .delete();
      } catch (e) {
        throw Exception('Failed to delete subscription: $e');
      }
    }




    Future<void> fetchMarks(String studentId) async {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection('marks')
            .orderBy('timestamp', descending: true)
            .get();

        final marks = snapshot.docs
            .map((doc) => MarkModel.fromJson(doc.data()))
            .toList();

        emit(MarksLoaded(marks));
      } catch (e) {
        emit(UsersError(e.toString()));
      }
    }

    Future<void> fetchSubscriptions(String studentId) async {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection('subscriptions')
            .where('active', isEqualTo: true)
            .orderBy('timestamp', descending: true)
            .get();

        final subscriptions = snapshot.docs
            .map((doc) => SubscriptionModel.fromJson(doc.data()))
            .toList();

        emit(SubscriptionsLoaded(subscriptions));
      } catch (e) {
        emit(UsersError(e.toString()));
      }
    }

    Future<void> deleteItem({
      required String studentId,
      required String itemId,
      required String collection,
    }) async {
      try {
        // Fetch the item first for potential rollback
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection(collection)
            .doc(itemId)
            .get();

        if (!doc.exists) {
          throw Exception('Item not found');
        }

        final itemData = doc.data()!;

        // Soft delete by marking as inactive
        await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection(collection)
            .doc(itemId)
            .update({'active': false});

        final lastAction = {
          'type': 'delete_${collection}',
          'data': itemData,
          'timestamp': DateTime.now(),
        };

        emit(DataActionSuccess('تم الحذف بنجاح', itemId));

        // Show rollback option for 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (collection == 'marks') {
            fetchMarks(studentId);
          } else {
            fetchSubscriptions(studentId);
          }
        });
      } catch (e) {
        emit(UsersError(e.toString()));
      }
    }

    Future<void> undoLastAction(String studentId) async {
      try {
        if (state is DataActionSuccess) {
          final successState = state as DataActionSuccess;
          // Implement rollback logic based on action type
          // Re-add deleted item or reverse the last change
        }
      } catch (e) {
        emit(UsersError(e.toString()));
      }
    }
    void setSelectedExamRange(String newRange) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      selectedExamRange = newRange;
      prefs.setString('selectedExamRange', newRange);

      // Update state while preserving users
      if (state is UsersLoaded) {
        emit((state as UsersLoaded).copyWith(selectedExamRange: newRange));
      }
    }

    void setSelectedTeacher(String teacherName) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      selectedTeacher = teacherName;
      prefs.setString('selectedTeacher', teacherName);

      // Update state while preserving users
      if (state is UsersLoaded) {
        emit((state as UsersLoaded).copyWith(selectedTeacher: teacherName));
      }
    }
    // New method to toggle search mode
    void toggleSearchMode(bool enabled) {
      isSearchMode = enabled;
      if (!enabled) {
        searchResults.clear();
        lastSearchQuery = '';
        emit(UsersLoaded(users, isSearching: false));
      } else {
        emit(UsersLoaded(users, isSearching: true));
      }
    }

    // Enhanced search method
    Future<void> searchUsers(String query) async {
      if (query.isEmpty) {
        searchResults.clear();
        emit(UsersLoaded(users, isSearching: true));
        return;
      }

      emit(UsersLoading());
      lastSearchQuery = query;

      try {
        // Normalize the search query
        query = normalizeSearchQuery(query);

        // Create a query based on the input type
        Query searchQuery = createSearchQuery(query);

        // Execute the search
        final QuerySnapshot querySnapshot = await searchQuery.limit(20).get();

        searchResults = querySnapshot.docs
            .map((doc) => UserModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        emit(UsersLoaded(searchResults, isSearching: true));
      } catch (error) {
        emit(UsersError('Search failed: ${error.toString()}'));
      }
    }

    // Helper method to normalize search query
    String normalizeSearchQuery(String query) {
      // Remove whitespace
      query = query.trim();

      // Convert Arabic numerals to English
      final arabicNumerals = {'٠':'0','١':'1','٢':'2','٣':'3','٤':'4',
        '٥':'5','٦':'6','٧':'7','٨':'8','٩':'9'};
      arabicNumerals.forEach((arabic, english) {
        query = query.replaceAll(arabic, english);
      });

      // Remove country code if present
      if (query.startsWith('+2')) {
        query = query.substring(2);
      }

      return query;
    }

    // Helper method to create appropriate search query
    Query createSearchQuery(String query) {
      final bool isPhone = RegExp(r'^(01|\+201|00201)').hasMatch(query);

      if (isPhone) {
        return FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .where('phone', isGreaterThanOrEqualTo: query)
            .where('phone', isLessThan: query + 'z');
      } else {
        // Create name search query with case-insensitive search
        return FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .orderBy('name')
            .startAt([query.toLowerCase()])
            .endAt([query.toLowerCase() + '\uf8ff']);
      }
    }

    // Method to clear search and restore original list
    void clearSearch() {
      searchResults.clear();
      lastSearchQuery = '';
      toggleSearchMode(false);
    }


    // Fetch initial users with role 'user'
    Future<void> fetchUsers() async {
      emit(UsersLoading());
      try {
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .orderBy('name') // Add consistent ordering
            .limit(12)
        //server then
            .get(GetOptions(source: Source.serverAndCache));

        if (querySnapshot.docs.isEmpty) {
          emit(UsersLoaded([]));
          return;
        }

        users = querySnapshot.docs.map((doc) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();

        lastDocument = querySnapshot.docs.last;
        hasMoreData = querySnapshot.docs.length == 12;

        emit(UsersLoaded(users));
      } catch (error) {
        emit(UsersError(error.toString()));
      }
    }

    // Fetch more users for pagination
    Future<void> fetchMoreUsers() async {
      if (!hasMoreData || isLoadingMore || lastDocument == null) return;

      isLoadingMore = true;
      emit(UsersLoadingMore(users)); // New state to show loading indicator

      try {
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .orderBy('name') // Add consistent ordering
            .startAfterDocument(lastDocument!)
            .limit(12)
            .get();

        if (querySnapshot.docs.isEmpty) {
          hasMoreData = false;
          isLoadingMore = false;
          emit(UsersLoaded(users));
          return;
        }

        final newUsers = querySnapshot.docs.map((doc) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();

        users.addAll(newUsers);
        lastDocument = querySnapshot.docs.last;
        hasMoreData = querySnapshot.docs.length == 12;

        emit(UsersLoaded(users));
      } catch (error) {
        emit(UsersError(error.toString()));
      } finally {
        isLoadingMore = false;
      }
    }

    // Fetch initial users with role 'user'
    // void fetchUsers() {
    //   FirebaseFirestore.instance
    //       .collection('users')
    //       .where('role', isEqualTo: 'user')
    //       .limit(12)
    //       .get()
    //       .then((QuerySnapshot querySnapshot) {
    //     users = querySnapshot.docs.map((doc) {
    //       return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    //     }).toList();
    //     emit(UsersLoaded(users));
    //   });
    // }

    // Load saved exam range and teacher from SharedPreferences
    void loadPreferences() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      selectedExamRange = prefs.getString('selectedExamRange') ?? '10';
      selectedTeacher = prefs.getString('selectedTeacher') ?? '';
      emit(PreferencesLoaded(selectedExamRange!, selectedTeacher!));
    }

    // Save selected exam range to SharedPreferences
    // void setSelectedExamRange(String newRange) async {
    //   SharedPreferences prefs = await SharedPreferences.getInstance();
    //   selectedExamRange = newRange;
    //   prefs.setString('selectedExamRange', newRange);
    //   emit(ExamRangeSelected(newRange));
    // }
    //
    // // Save selected teacher to SharedPreferences
    // void setSelectedTeacher(String teacherName) async {
    //   SharedPreferences prefs = await SharedPreferences.getInstance();
    //   selectedTeacher = teacherName;
    //   prefs.setString('selectedTeacher', teacherName);
    //   emit(TeacherSelected(teacherName));
    // }

    // Fetch initial users with role 'user'

    // Fetch more users for pagination
    // void fetchMoreUsers() {
    //   if (lastDocument != null && !isLoadingMore) {
    //     isLoadingMore = true; // Set loading state
    //
    //     FirebaseFirestore.instance
    //         .collection('users')
    //         .where('role', isEqualTo: 'user')
    //         .startAfterDocument(
    //         lastDocument!) // Start after the last document fetched
    //         .limit(5) // Fetch next 5 items
    //         .get()
    //         .then((QuerySnapshot querySnapshot) {
    //       List<UserModel> moreUsers = querySnapshot.docs.map((doc) {
    //         return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    //       }).toList();
    //
    //       if (moreUsers.isNotEmpty) {
    //         users.addAll(moreUsers); // Add new users to the existing list
    //         lastDocument =
    //             querySnapshot.docs.last; // Update the last document reference
    //       } else {
    //         lastDocument = null; // No more documents to fetch
    //       }
    //
    //       emit(UsersLoaded(users));
    //       isLoadingMore = false; // Reset loading state
    //     });
    //   }
    // }

    Future<void>? updateUserInfo({required String fname,
      required String lname,
      required String phone,
      String? hourlyRate,
      // String? password,
      required uid, required String? numberOfSessions}) async {
      emit(UpdateUserInfoLoadingState());
      //  if (password.isEmpty) {
      //    password = '123456';
      //  }
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
      // Inside your function
//bool isConnected = await checkInternetConnection();
// if (!isConnected) {
//
//   // Show error message to the user
//   //show toast message
//   showToast(
//     state: ToastStates.ERROR,
//     msg: ' فشل تحديث معلومات الحساب الشخصية'
//     'تأكد من اتصالك بالإنترنت'
//   );
//   emit(UpdateUserInfoErrorState('تأكد من اتصالك بالإنترنت'));
// }
      final updateData = <String, Object?>{};


      final notificationData = <String, dynamic>{};
      if (hourlyRate != null && hourlyRate != '' && hourlyRate != 'null') {
        updateData['hourlyRate'] = int.parse(hourlyRate);
        notificationData['message'] = 'تم تحديث معلومات الحساب الشخصية';
      }
      if (numberOfSessions != null &&
          numberOfSessions != '' &&
          numberOfSessions != 'null') {
        updateData['numberOfSessions'] = int.parse(numberOfSessions);
        notificationData['message'] = 'تم تحديث معلومات الحساب الشخصية';
      }
      if (fname != null &&
          lname != null &&
          fname != '' &&
          lname != '' &&
          fname != 'null' &&
          lname != 'null') {
        updateData['name'] = '$fname $lname';
        updateData['fname'] = fname;
        updateData['lname'] = lname;

        //userData!.name = firstName + ' ' + (lastName ?? '');
      }
      //password
      if (fname != null && fname != '' && fname != 'null') {
        updateData['fname'] = fname;
        notificationData['message'] = 'تم تحديث معلومات الحساب الشخصية';
      }
      if (lname != null && lname != '' && lname != 'null') {
        updateData['lname'] = lname;
        notificationData['message'] = 'تم تحديث معلومات الحساب الشخصية';
      }
      if (phone != null && phone != '' && phone != 'null') {
        updateData['phone'] = phone.toString();
        notificationData['message'] = 'تم تحديث معلومات الحساب الشخصية';
      }
      //print updateData

      notificationData['timestamp'] = DateTime.now();
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(uid)
      //     .collection('notifications')
      //     .add(notificationData);
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);
      //if internet is not available show toast message
      //and emit state
      showToast(
        state: ToastStates.SUCCESS,
        msg: 'تم تحديث معلومات الحساب الشخصية',
      );
      emit(UpdateUserInfoSuccessState());
    }

    late TextEditingController firstNameController;
    late TextEditingController lastNameController;
    late TextEditingController phoneController;
    late TextEditingController salaryPerHourController;

    //numberOfSessionsController
    late TextEditingController numberOfSessionsController;
    late TextEditingController passwordController;

    // Initialize controllers for a specific user
    final formKey = GlobalKey<FormState>();

    deleteUser({required String uid}) {
      emit(DeleteUserLoadingState());

      // Delete the user document
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete()
          .then((value) {
        // Delete the user's subcollection "schedules"
        CollectionReference schedulesCollection =
        FirebaseFirestore.instance.collection('users').doc(uid).collection(
            'schedules');
        schedulesCollection.get().then((schedulesSnapshot) {
          WriteBatch batch = FirebaseFirestore.instance.batch();
          schedulesSnapshot.docs.forEach((doc) {
            batch.delete(doc.reference);
          });
          batch.commit().then((_) {
            // Show toast message
            showToast(
              state: ToastStates.SUCCESS,
              msg: 'تم حذف المستخدم والجداول الفرعية',
            );
            emit(DeleteUserSuccessState());
          }).catchError((error) {
            showToast(
              msg: 'فشل حذف الجداول الفرعية',
              state: ToastStates.ERROR,
            );
            emit(DeleteUserErrorState(error.toString()));
          });
        });
      }).catchError((error) {
        showToast(
          msg: 'فشل حذف المستخدم',
          state: ToastStates.ERROR,
        );
        emit(DeleteUserErrorState(error.toString()));
      });
    }

    initControllers(userModel) {
      firstNameController = TextEditingController(text: userModel.fname);
      lastNameController = TextEditingController(text: userModel.lname);
      phoneController = TextEditingController(text: userModel.phone);
      salaryPerHourController =
          TextEditingController(text: userModel.hourlyRate.toString() ?? '');
      //numberOfSessionsController
      numberOfSessionsController =
          TextEditingController(
              text: userModel.numberOfSessions.toString() ?? '');
      //passwordController
      passwordController = TextEditingController(
        text: userModel.password.toString() ?? '',
      );
    }


    Future<void> onSearchSubmitted(String value, bool isCoach) async {
      emit(UsersLoading());

      // Convert Arabic numerals to English numerals
      if (value.startsWith('٠١')) {
        value = value
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
      }

      // Remove spaces from phone numbers
      value = value.replaceAll(' ', '');

      // Detect if the value is a phone number (e.g., starts with 01 or +2)
      bool isPhone = value.startsWith('01') || value.startsWith('+2');
      try {
        late Query newQuery;
        if (isPhone) {
          // Phone number search (handle case with or without country code)
          newQuery = FirebaseFirestore.instance
              .collection('users')
              .where('phone', isGreaterThanOrEqualTo: value)
              .where('phone', isLessThan: value + 'z')
              .where('role', isEqualTo: isCoach ? 'coach' : 'user');
        } else {
          // Name search, case-insensitive (use where for name search, filter by role)
          newQuery = FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: isCoach ? 'coach' : 'user')
              .orderBy('name')
              .startAt([value])
              .endAt([value + '\uf8ff']); // Ensure name matches with prefix

        }

        // Fetch results from the query
        QuerySnapshot querySnapshot = await newQuery.get();

        List<UserModel> users = querySnapshot.docs.map((doc) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();

        emit(UsersLoaded(users)); // Emit new state with loaded users
      } catch (e) {
        print('Search Error: $e');
        emit(UsersLoaded(
            [])); // In case of error, show empty list or handle error
      }
    }

    static ManageStudentsCubit get(BuildContext context) =>
        BlocProvider.of<ManageStudentsCubit>(context);

    void fetchTeachers() {
      FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .limit(12)
          .get()
          .then((QuerySnapshot querySnapshot) {
        coaches = querySnapshot.docs.map((doc) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();
        //emit(UsersLoaded(coaches))
        // save the coaches in shared preferences
        saveCoachesInSharedPref(coaches);
      });
    }

    Future<void> saveCoachesInSharedPref(List<UserModel> coaches) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> teachers = coaches.map((e) => e.name!).toList();
      prefs.setStringList('teachers', teachers);
    }

    // loadCoachesFromPrefs() {}
Future<List<UserModel>> loadCoachesFromPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? teachers = prefs.getStringList('teachers');
  if (teachers != null) {
    coaches = teachers.map((e) => UserModel(name: e, teachers: [])).toList();
  }
  return coaches;
}
  }
