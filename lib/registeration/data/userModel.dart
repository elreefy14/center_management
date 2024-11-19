import 'package:cloud_firestore/cloud_firestore.dart';
class UserModel
{
  Timestamp? lastPaymentDate;
  Timestamp? lastModifiedDate;
  Timestamp? lastAttendance;
  String? lastPaymentNote;
  String? name;
  String? email;
  int? level;
  int? hourlyRate;
  int? totalHours;
  int? totalSalary;
  int? currentMonthHours;
  int? currentMonthSalary;
  String? uId;
  String? phone;
  String? parentPhone;
  String? fname;
  String? lname;
  String? image;
  String? token;
  List<String>? branches;
  String? role;
  Timestamp? date;
  //pid
  String? pid;
  //numberOfSessions
  int? numberOfSessions;
  String? password;
  //teachers
  List<String>? teachers;
  List<String>? attendanceDates; // Add this line




  UserModel({
    this.role,
    this.name,
    this.email,
    this.level,
    this.hourlyRate,
    this.totalHours,
    this.totalSalary,
    this.currentMonthHours,
    this.currentMonthSalary,
    this.uId,
    this.phone,
    this.parentPhone,
    this.fname,
    this.lname,
    this.image,
    this.token,
    this.branches,
    this.lastPaymentDate,
    this.lastAttendance,
    this.lastModifiedDate,
    this.lastPaymentNote,
    this.pid, this.numberOfSessions,
    this.attendanceDates, // Add this line
    this.date, this.password, required List<String> teachers,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    name = json['name'];
    email = json['email'];
    level = json['level'];
    hourlyRate = json['hourlyRate'];
    totalHours = json['totalHours'];
    lastPaymentDate = json['lastPaymentDate'];
    lastModifiedDate = json['lastModifiedDate'];
    lastPaymentNote = json['lastPaymentNote'];
    lastPaymentNote = json['lastAttendance'];
    totalSalary = json['totalSalary'];
    currentMonthHours = json['currentMonthHours'];
    currentMonthSalary = json['currentMonthSalary'];
    uId = json['uId'];
    phone = json['phone'];
    phone = json['parentPhone'];
    fname = json['fname'];
    lname = json['lname'];
    image = json['image'];
    token = json['token'];
    pid = json['pid'];
    branches = json['branches'] != null ? List<String>.from(json['branches']) : null;
    numberOfSessions = json['numberOfSessions'];
    date = json['date'];
    password = json['password'];
    teachers = json['teachers'] != null ? List<String>.from(json['teachers']) : null;

  }

  Map<String, dynamic> toJson() {

    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['role'] = this.role;
    data['name'] = this.name;
    data['email'] = this.email;

    data['level'] = this.level;
    data['hourlyRate'] = this.hourlyRate;
    data['totalHours'] = this.totalHours;
    data['totalSalary'] = this.totalSalary;
    data['currentMonthHours'] = this.currentMonthHours;
    data['currentMonthSalary'] = this.currentMonthSalary;
    data['uId'] = this.uId;
    data['phone'] = this.phone;
    data['parentPhone'] = this.parentPhone;
    data['fname'] = this.fname;
    data['lname'] = this.lname;
    data['image'] = this.image;
    data['token'] = this.token;
    data['branches'] = this.branches;
    data['pid'] = this.pid;
    data['numberOfSessions'] = this.numberOfSessions;
    data['date'] = this.date;
    data['password'] = this.password;
    data['attendanceDates'] = this.attendanceDates; // Add this line

    data['teachers'] = this.teachers;

    return data;

  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'email': email,
      'lastPaymentDate': lastPaymentDate,
      'lastModifiedDate': lastModifiedDate,
      'lastAttendance': lastAttendance,
      'lastPaymentNote': lastPaymentNote,
      'level': level,
      'hourlyRate': hourlyRate,
      'totalHours': totalHours,
      'totalSalary': totalSalary,
      'currentMonthHours': currentMonthHours,
      'currentMonthSalary': currentMonthSalary,
      'uId': uId,
      'phone': phone,
      'parentPhone': parentPhone,
      'fname': fname,
      'lname': lname,
      'image': image,
      'token': token,
      'branches': branches,
      'pid': pid,
      'numberOfSessions': numberOfSessions,
      'date': date,
      'password': password,
      'teachers': teachers,
      'attendanceDates': attendanceDates, // Add this line

    };

  }
}



