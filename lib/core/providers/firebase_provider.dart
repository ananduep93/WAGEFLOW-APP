import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../../models/worker.dart';
import '../../models/attendance.dart';
import '../../models/payment.dart';
import '../../models/advance_request.dart';
import '../../models/project.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());

final workersStreamProvider = StreamProvider<List<Worker>>((ref) {
  return ref.watch(firebaseServiceProvider).getWorkers();
});

final allProjectsStreamProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(firebaseServiceProvider).getProjects();
});

// For workers to find their own record linked by email
final myWorkerRecordProvider = StreamProvider<Worker?>((ref) {
  return ref.watch(firebaseServiceProvider).getMyWorkerRecord();
});

final paymentsStreamProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllPaymentsForOwner();
});

final allPaymentsStreamProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllPaymentsForOwner();
});

final attendanceStreamProvider = StreamProvider.family<List<Attendance>, String>((ref, workerId) {
  return ref.watch(firebaseServiceProvider).getAttendanceForWorker(workerId);
});

final allAttendanceStreamProvider = StreamProvider<List<Attendance>>((ref) {
  return ref.watch(firebaseServiceProvider).getAllAttendanceForOwner();
});

final paymentsForWorkerStreamProvider = StreamProvider.family<List<Payment>, String>((ref, workerId) {
  return ref.watch(firebaseServiceProvider).getPaymentsForWorker(workerId);
});

final advanceRequestsForWorkerProvider = StreamProvider.family<List<AdvanceRequest>, String>((ref, workerId) {
  return ref.watch(firebaseServiceProvider).getAdvanceRequestsForWorker(workerId);
});

final ownerAdvanceRequestsProvider = StreamProvider<List<AdvanceRequest>>((ref) {
  return ref.watch(firebaseServiceProvider).getAdvanceRequestsForOwner();
});
