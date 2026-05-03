import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/attendance.dart';

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, List<Attendance>>((ref) {
  return AttendanceNotifier();
});

class AttendanceNotifier extends StateNotifier<List<Attendance>> {
  AttendanceNotifier() : super([]) {
    _loadAttendance();
  }

  final _box = Hive.box<Attendance>('attendance');

  void _loadAttendance() {
    state = _box.values.toList();
  }

  Future<void> markAttendance(String workerId, DateTime date, AttendanceStatus status, double wage) async {
    final id = "${workerId}_${date.year}${date.month}${date.day}";
    final attendance = Attendance(
      id: id,
      workerId: workerId,
      date: date,
      status: status,
      calculatedWage: wage,
    );
    await _box.put(id, attendance);
    
    // Update local state: replace if exists, else add
    final index = state.indexWhere((a) => a.id == id);
    if (index != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) attendance else state[i]
      ];
    } else {
      state = [...state, attendance];
    }
  }
}
