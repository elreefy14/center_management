// attendance_state.dart
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

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

  Future<void> loadAttendance(DateTime date, {bool refresh = false}) async {
    try {
      if (refresh) {
        _lastDocument = null;
        _records.clear();
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

      _records.addAll(newRecords.where((newRecord) => !_records.any((record) => record.studentId == newRecord.studentId && record.date == newRecord.date)));

      _hasMore = querySnapshot.docs.length == _pageSize;

      emit(AttendanceLoaded(_records, hasMore: _hasMore));
    } catch (error) {
      emit(AttendanceError('حدث خطأ أثناء تحميل سجلات الحضور'));
    }
  }

  void resetPagination() {
    _lastDocument = null;
    _records.clear();
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
          if (state is AttendanceLoading && !(state is AttendanceLoaded)) {
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الطالب: ${record.studentName}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'التاريخ: ${record.date}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الوقت: ${record.hour}:${record.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

