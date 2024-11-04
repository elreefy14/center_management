// attendance_state.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AttendanceState {}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final List<AttendanceRecord> records;
  final bool hasMore;

  AttendanceLoaded(this.records, {this.hasMore = true});
}

class AttendanceError extends AttendanceState {
  final String message;
  AttendanceError(this.message);
}

class AttendanceAdded extends AttendanceState {}

// attendance_model.dart
class AttendanceRecord {
  final String studentId;
  final String studentName;
  final DateTime timestamp;
  final String date;
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.timestamp,
    required this.date,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentId: json['studentId'],
      studentName: json['studentName'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      date: json['date'],
      year: json['year'],
      month: json['month'],
      day: json['day'],
      hour: json['hour'],
      minute: json['minute'],
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'timestamp': timestamp,
    'date': date,
    'year': year,
    'month': month,
    'day': day,
    'hour': hour,
    'minute': minute,
  };
}

// attendance_cubit.dart
class AttendanceCubit extends Cubit<AttendanceState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  List<AttendanceRecord> _records = [];
  DateTime? _selectedDate;

  AttendanceCubit() : super(AttendanceInitial());

  Future<void> handleBarcodeScanned(String studentId, BuildContext context) async {
    try {
      emit(AttendanceLoading());

      final WriteBatch batch = _firestore.batch();
      final DateTime now = DateTime.now();

      // Get student data
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      if (!studentDoc.exists) {
        throw Exception('Student not found');
      }

      final String studentName = '${studentDoc.get('fname')} ${studentDoc.get('lname')}';

      final Map<String, dynamic> attendanceData = {
        'studentId': studentId,
        'studentName': studentName,
        'timestamp': now,
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'year': now.year,
        'month': now.month,
        'day': now.day,
        'hour': now.hour,
        'minute': now.minute,
      };

      // Add to student's attendance subcollection
      final studentAttendanceRef = _firestore
          .collection('users')
          .doc(studentId)
          .collection('attendance')
          .doc('${now.year}-${now.month}-${now.day}');

      batch.set(studentAttendanceRef, attendanceData);

      // Add to general attendance collection
      final generalAttendanceRef = _firestore
          .collection('attendance')
          .doc('${now.year}-${now.month}-${now.day}-$studentId');

      batch.set(generalAttendanceRef, attendanceData);

      // Update student's attendance summary
      final studentRef = _firestore.collection('users').doc(studentId);
      batch.update(studentRef, {
        'lastAttendance': now,
        'attendanceDates': FieldValue.arrayUnion([attendanceData['date']]),
      });

      await batch.commit();

      // Reload attendance list if we're viewing today's attendance
      if (_selectedDate?.year == now.year &&
          _selectedDate?.month == now.month &&
          _selectedDate?.day == now.day) {
        await loadAttendance(_selectedDate!);
      }

      emit(AttendanceAdded());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الحضور بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error recording attendance: $error');
      emit(AttendanceError('حدث خطأ أثناء تسجيل الحضور'));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تسجيل الحضور'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> loadAttendance(DateTime date, {bool refresh = false}) async {
    try {
      if (refresh) {
        _lastDocument = null;
        _records = [];
        _hasMore = true;
      }

      if (!_hasMore) return;

      _selectedDate = date;
      emit(AttendanceLoading());

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      var query = _firestore
          .collection('attendance')
          .where('date', isEqualTo: dateStr)
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        _hasMore = false;
        emit(AttendanceLoaded(_records, hasMore: false));
        return;
      }

      _lastDocument = querySnapshot.docs.last;

      final newRecords = querySnapshot.docs
          .map((doc) => AttendanceRecord.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      _records.addAll(newRecords);
      _hasMore = querySnapshot.docs.length == _pageSize;

      emit(AttendanceLoaded(_records, hasMore: _hasMore));
    } catch (error) {
      print('Error loading attendance: $error');
      emit(AttendanceError('حدث خطأ أثناء تحميل سجلات الحضور'));
    }
  }

  void resetPagination() {
    _lastDocument = null;
    _records = [];
    _hasMore = true;
  }
}

// attendance_screen.dart
class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTime selectedDate = DateTime.now();
  late AttendanceCubit _attendanceCubit;

  @override
  void initState() {
    super.initState();
    _attendanceCubit = context.read<AttendanceCubit>();
    _attendanceCubit.loadAttendance(selectedDate, refresh: true);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _attendanceCubit.loadAttendance(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الحضور'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (context, state) {
          if (state is AttendanceLoading &&
              !(state is AttendanceLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AttendanceError) {
            return Center(child: Text(state.message));
          }

          if (state is AttendanceLoaded) {
            if (state.records.isEmpty) {
              return const Center(child: Text('لا يوجد سجلات حضور'));
            }

            return RefreshIndicator(
              onRefresh: () => _attendanceCubit.loadAttendance(selectedDate, refresh: true),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: state.records.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.records.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final record = state.records[index];
                  return AttendanceRecordTile(record: record);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _attendanceCubit.loadAttendance(selectedDate, refresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// attendance_record_tile.dart
class AttendanceRecordTile extends StatelessWidget {
  final AttendanceRecord record;

  const AttendanceRecordTile({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.chevron_right,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.date} - ${record.hour}:${record.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
