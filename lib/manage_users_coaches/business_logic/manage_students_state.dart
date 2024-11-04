part of 'manage_students_cubit.dart';

@immutable
sealed class ManageStudentsState {}

final class ManageStudentsInitial extends ManageStudentsState {}
//class UsersLoading extends ManageUsersState {}
//
// class UsersLoaded extends ManageUsersState {
//   final List<UserModel> users;
//
//   UsersLoaded(this.users);
// }
class UsersLoading extends ManageStudentsState {}
//fetche users Loading
class FetchUsersLoading extends ManageStudentsState {}
//emit(UsersLoaded(searchResults, isSearching: true));

class UsersLoaded extends ManageStudentsState {
  final List<UserModel> users;
  final bool isSearching;
  final String? selectedExamRange;
  final String? selectedTeacher;

  UsersLoaded(
    this.users, {
    this.isSearching = false,
    this.selectedExamRange,
    this.selectedTeacher,
  });

  // Add copyWith method to create new instance with updated values
  UsersLoaded copyWith({
    List<UserModel>? users,
    bool? isSearching,
    String? selectedExamRange,
    String? selectedTeacher,
  }) {
    return UsersLoaded(
      users ?? this.users,
      isSearching: isSearching ?? this.isSearching,
      selectedExamRange: selectedExamRange ?? this.selectedExamRange,
      selectedTeacher: selectedTeacher ?? this.selectedTeacher,
    );
  }
}
//UpdateUserInfoErrorState
class UpdateUserInfoErrorState extends ManageStudentsState {
  final String error;
  UpdateUserInfoErrorState(this.error);
}
//UpdateUserInfoLoadingState
class UpdateUserInfoLoadingState extends ManageStudentsState {}
//UpdateUserInfoSuccessState
class UpdateUserInfoSuccessState extends ManageStudentsState {}
//DeleteUserLoadingState
class DeleteUserLoadingState extends ManageStudentsState {}
//DeleteUserSuccessState
class DeleteUserSuccessState extends ManageStudentsState {}
//emit(DataActionSuccess('تم إضافة الدرجة بنجاح', markModel.id));
//emit(DataActionSuccess('تم إضافة الدرجة بنجاح', markModel.id));
//emit(DataActionSuccess('تم إضافة الدرجة بنجاح', markModel.id));
class DataActionSuccess extends ManageStudentsState {
  final String message;
  final String id;
  DataActionSuccess(this.message, this.id);
}
//emit(MarksLoaded(marks));
class MarksLoaded extends ManageStudentsState {
  final List<MarkModel> marks;
  MarksLoaded(this.marks);
}
//emit(SubscriptionsLoaded(subscriptions));
class SubscriptionsLoaded extends ManageStudentsState {
  final List<SubscriptionModel> subscriptions;
  SubscriptionsLoaded(this.subscriptions);
}

class PreferencesLoaded extends ManageStudentsState {
  final String selectedExamRange;
  final String selectedTeacher;
  PreferencesLoaded(this.selectedExamRange, this.selectedTeacher);
}

class ExamRangeSelected extends ManageStudentsState {
  final String examRange;
  ExamRangeSelected(this.examRange);
}

class TeacherSelected extends ManageStudentsState {
  final String teacherName;
  TeacherSelected(this.teacherName);
}




class UsersLoadingMore extends ManageStudentsState {
  final List<UserModel> currentUsers;
  UsersLoadingMore(this.currentUsers);
}



class UsersError extends ManageStudentsState {
  final String message;
  UsersError(this.message);
}

//DeleteUserErrorState
class DeleteUserErrorState extends ManageStudentsState {
  final String error;
  DeleteUserErrorState(this.error);
}
