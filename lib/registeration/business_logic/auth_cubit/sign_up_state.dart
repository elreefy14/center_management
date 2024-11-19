abstract class SignUpState {}
//InitialState
//GetCoachesLoadingState
class GetCoachesLoadingState extends SignUpState {}
//GetCoachesSuccessState
class GetCoachesSuccessState extends SignUpState {
  final List<String>? coaches;
  GetCoachesSuccessState({this.coaches});
}
//GetCoachesErrorState
class GetCoachesErrorState extends SignUpState {
  final String? error;
  GetCoachesErrorState({this.error});
}class ImportErrorState extends SignUpState {
  final String? e;
  ImportErrorState({this.e});
}
//emit(UpdateSelectedTeachersState(selectedTeachers: selectedTeachers));
class UpdateSelectedTeachersState extends SignUpState {
  final List<String>? selectedTeachers;
  UpdateSelectedTeachersState({this.selectedTeachers});
}


class InitialState extends SignUpState {}
//ChangePasswordVisibilityState
class ChangePasswordVisibilityState extends SignUpState {}
//SignUpLoadingState
class SignUpLoadingState extends SignUpState {}
//SignUpSuccessState
class SignUpSuccessState extends SignUpState {
  final String uId;
  SignUpSuccessState(this.uId);
}class ImportSuccessState extends SignUpState {
  ImportSuccessState();
}
//SignUpErrorState
class SignUpErrorState extends SignUpState {
  final String? error;
  SignUpErrorState({this.error});
}
//CreateUserLoadingState
class CreateUserLoadingState extends SignUpState {}
//CreateUserSuccessState
class CreateUserSuccessState extends SignUpState {
  final String uId;
  CreateUserSuccessState(this.uId);
}
//CreateUserErrorState
class CreateUserErrorState extends SignUpState {}
//UpdatePasswordLoadingState
class UpdatePasswordLoadingState extends SignUpState {}
//UpdatePasswordSuccessState
class UpdatePasswordSuccessState extends SignUpState {}
//UpdatePasswordErrorState
class UpdatePasswordErrorState extends SignUpState {
  final String? error;
  UpdatePasswordErrorState({this.error});
}
//UpdateSelectedItemsState
class UpdateSelectedItemsState extends SignUpState {
  final List<String>? selectedItems;
  UpdateSelectedItemsState({this.selectedItems});
}
//AddBranchesLoadingState
class AddBranchesLoadingState extends SignUpState {}
//AddBranchesSuccessState
class AddBranchesSuccessState extends SignUpState {}
//AddBranchesErrorState
class AddBranchesErrorState extends SignUpState {
  final String? error;
  AddBranchesErrorState({this.error});
}
//GetBranchesLoadingState
class GetBranchesLoadingState extends SignUpState {}
//GetBranchesSuccessState
class GetBranchesSuccessState extends SignUpState {
  final List<String>? branches;
  GetBranchesSuccessState({this.branches});
}
//GetBranchesErrorState
class GetBranchesErrorState extends SignUpState {
  final String? error;
  GetBranchesErrorState({this.error});
}
//UpdateControllersState
class UpdateControllersState extends SignUpState {
  final String? firstName;
  final String? lastName;
  final String? phone;
  UpdateControllersState({this.firstName, this.lastName, this.phone});
}