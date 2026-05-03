import 'package:hive/hive.dart';

part 'attendance.g.dart';

@HiveType(typeId: 1)
enum AttendanceStatus {
  @HiveField(0)
  present,
  @HiveField(1)
  absent,
  @HiveField(2)
  halfDay
}

@HiveType(typeId: 2)
class Attendance extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String workerId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final AttendanceStatus status;

  @HiveField(4)
  final double calculatedWage;

  @HiveField(5)
  final String? businessId; // Link to Owner

  @HiveField(6)
  final String? projectId; // Link to Site

  Attendance({
    required this.id,
    required this.workerId,
    required this.date,
    required this.status,
    required this.calculatedWage,
    this.businessId,
    this.projectId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'date': date.toIso8601String(),
      'status': status.name,
      'calculatedWage': calculatedWage,
      'businessId': businessId,
      'projectId': projectId,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] ?? '',
      workerId: map['workerId'] ?? '',
      date: DateTime.parse(map['date']),
      status: AttendanceStatus.values.byName(map['status']),
      calculatedWage: (map['calculatedWage'] ?? 0.0).toDouble(),
      businessId: map['businessId'],
      projectId: map['projectId'],
    );
  }
}
