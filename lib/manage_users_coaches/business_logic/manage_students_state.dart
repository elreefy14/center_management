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
class UsersLoaded extends ManageStudentsState {
  final List<UserModel> users;

  UsersLoaded(this.users);
}
//UpdateUserInfoLoadingState
class UpdateUserInfoLoadingState extends ManageStudentsState {}
//UpdateUserInfoSuccessState
class UpdateUserInfoSuccessState extends ManageStudentsState {}
//DeleteUserLoadingState
class DeleteUserLoadingState extends ManageStudentsState {}
//DeleteUserSuccessState
class DeleteUserSuccessState extends ManageStudentsState {}

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
//DeleteUserErrorState
class DeleteUserErrorState extends ManageStudentsState {
  final String error;
  DeleteUserErrorState(this.error);
}
