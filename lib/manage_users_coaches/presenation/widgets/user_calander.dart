import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAttendanceCalendar extends StatefulWidget {
  final String userId;
  final List<String> attendanceDates;

  const UserAttendanceCalendar({
    Key? key,
    required this.userId,
    required this.attendanceDates,
  }) : super(key: key);

  @override
  State<UserAttendanceCalendar> createState() => _UserAttendanceCalendarState();
}

class _UserAttendanceCalendarState extends State<UserAttendanceCalendar> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  late Set<String> _formattedAttendanceDates;

  @override
  void initState() {
    super.initState();
    _formattedAttendanceDates = widget.attendanceDates.toSet();
  }

  @override
  void didUpdateWidget(UserAttendanceCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendanceDates != widget.attendanceDates) {
      _formattedAttendanceDates = widget.attendanceDates.toSet();
    }
  }

  bool _hasAttendance(DateTime day) {
    final formattedDate = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _formattedAttendanceDates.contains(formattedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              if (_hasAttendance(selectedDay)) {
                _showAttendanceDetails(context, selectedDay);
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, isSelected: false);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, isSelected: true);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, isToday: true);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green.shade300, 'Present'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.grey.shade200, 'Absent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, {bool isSelected = false, bool isToday = false}) {
    final hasAttendance = _hasAttendance(day);
    final backgroundColor = hasAttendance ? Colors.green.shade300 : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Colors.blue
              : isToday
              ? Colors.blue.shade200
              : Colors.grey.shade300,
          width: isSelected || isToday ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: hasAttendance ? Colors.white : Colors.black87,
            fontWeight: isSelected || isToday ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  void _showAttendanceDetails(BuildContext context, DateTime selectedDay) {
    final formattedDate = '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attendance - $formattedDate'),
        content: const Text('Student was present on this day'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}