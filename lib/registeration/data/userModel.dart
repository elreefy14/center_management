import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
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
  String? pid;
  int? numberOfSessions;
  String? password;
  String? groupCode;
  List<String>? teachers;
  List<String>? attendanceDates;

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
    this.groupCode,
    this.pid,
    this.numberOfSessions,
    this.attendanceDates,
    this.date,
    this.password,
    required this.teachers,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      role: json['role'],
      name: json['name'],
      email: json['email'],
      level: json['level'],
      hourlyRate: json['hourlyRate'],
      totalHours: json['totalHours'],
      groupCode: json['groupCode'],
      lastPaymentDate: json['lastPaymentDate'] != null
          ? (json['lastPaymentDate'] as Timestamp)
          : null,
      lastModifiedDate: json['lastModifiedDate'] != null
          ? (json['lastModifiedDate'] as Timestamp)
          : null,
      lastPaymentNote: json['lastPaymentNote'],
      lastAttendance: json['lastAttendance'] != null
          ? (json['lastAttendance'] as Timestamp)
          : null,
      totalSalary: json['totalSalary'],
      currentMonthHours: json['currentMonthHours'],
      currentMonthSalary: json['currentMonthSalary'],
      uId: json['uId'],
      phone: json['phone'],
      parentPhone: json['parentPhone'],
      fname: json['fname'],
      lname: json['lname'],
      image: json['image'],
      token: json['token'],
      pid: json['pid'],
      branches: json['branches'] != null
          ? List<String>.from(json['branches'])
          : null,
      numberOfSessions: json['numberOfSessions'],
      date: json['date'] != null ? (json['date'] as Timestamp) : null,
      password: json['password'],
      teachers: json['teachers'] != null
          ? List<String>.from(json['teachers'])
          : null,
      attendanceDates: json['attendanceDates'] != null
          ? List<String>.from(json['attendanceDates'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['role'] = role;
    data['name'] = name;
    data['email'] = email;
    data['lastPaymentDate'] = lastPaymentDate;
    data['lastModifiedDate'] = lastModifiedDate;
    data['lastAttendance'] = lastAttendance;
    data['groupCode'] = groupCode;
    data['lastPaymentNote'] = lastPaymentNote;
    data['level'] = level;
    data['hourlyRate'] = hourlyRate;
    data['totalHours'] = totalHours;
    data['totalSalary'] = totalSalary;
    data['currentMonthHours'] = currentMonthHours;
    data['currentMonthSalary'] = currentMonthSalary;
    data['uId'] = uId;
    data['phone'] = phone;
    data['parentPhone'] = parentPhone;
    data['fname'] = fname;
    data['lname'] = lname;
    data['image'] = image;
    data['token'] = token;
    data['branches'] = branches;
    data['pid'] = pid;
    data['numberOfSessions'] = numberOfSessions;
    data['date'] = date;
    data['password'] = password;
    data['teachers'] = teachers;
    data['attendanceDates'] = attendanceDates;
    return data;
  }
}