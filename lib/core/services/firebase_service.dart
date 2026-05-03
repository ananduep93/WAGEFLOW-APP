import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/worker.dart';
import '../../models/attendance.dart';
import '../../models/payment.dart';
import '../../models/advance_request.dart';
import '../../models/project.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  String? get _email => _auth.currentUser?.email;

  // OWNER: Get all workers added by this owner
  Stream<List<Worker>> getWorkers() {
    if (_uid == null) return Stream.value([]);
    return _firestore
        .collection('workers')
        .where('businessId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Worker.fromMap(doc.data())).toList());
  }

  // WORKER: Get the worker record that matches the logged-in worker's email
  Stream<Worker?> getMyWorkerRecord() {
    if (_email == null) return Stream.value(null);
    return _firestore
        .collection('workers')
        .where('email', isEqualTo: _email)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty 
            ? Worker.fromMap(snapshot.docs.first.data()) 
            : null);
  }

  Future<void> addWorker(Worker worker) async {
    if (_uid == null) return;
    final workerData = worker.toMap();
    workerData['businessId'] = _uid; // Link to Owner
    await _firestore.collection('workers').doc(worker.id).set(workerData);
  }

  Future<void> updateWorker(Worker worker) async {
    await _firestore.collection('workers').doc(worker.id).update(worker.toMap());
  }

  // ATTENDANCE
  Stream<List<Attendance>> getAttendanceForWorker(String workerId) {
    return _firestore
        .collection('attendance')
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Attendance.fromMap(doc.data())).toList());
  }

  // OWNER Dashboard: Get all attendance (to calculate totals) - Filtered by Business
  Stream<List<Attendance>> getAllAttendanceForOwner() {
    if (_uid == null) return Stream.value([]);
    return _firestore
        .collection('attendance')
        .where('businessId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Attendance.fromMap(doc.data())).toList());
  }

  Future<void> markAttendance(Attendance attendance) async {
    if (_uid == null) return;
    final data = attendance.toMap();
    data['businessId'] = _uid; // Link to Owner
    await _firestore.collection('attendance').doc(attendance.id).set(data);
  }

  // PAYMENTS
  Stream<List<Payment>> getPaymentsForWorker(String workerId) {
    return _firestore
        .collection('payments')
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList());
  }

  // OWNER Dashboard: Get all payments (to calculate totals) - Filtered by Business
  Stream<List<Payment>> getAllPaymentsForOwner() {
     if (_uid == null) return Stream.value([]);
     return _firestore
        .collection('payments')
        .where('businessId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList());
  }

  Future<void> addPayment(Payment payment) async {
    if (_uid == null) return;
    final data = payment.toMap();
    data['businessId'] = _uid; // Link to Owner
    await _firestore.collection('payments').doc(payment.id).set(data);
  }

  Future<void> deletePayment(String paymentId) async {
    await _firestore.collection('payments').doc(paymentId).delete();
  }
  
  // BUSINESS PROFILE
  Future<void> updateBusinessProfile(Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _firestore.collection('business').doc(_uid).set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> getBusinessProfile() {
    if (_uid == null) return Stream.value(null);
    return _firestore.collection('business').doc(_uid).snapshots().map((doc) => doc.data());
  }

  // ADVANCE REQUESTS
  Future<void> createAdvanceRequest(AdvanceRequest request) async {
    final data = request.toMap();
    if (_uid != null && request.businessId == null) {
      // If owner is creating for worker (rare but possible)
    }
    await _firestore.collection('advance_requests').doc(request.id).set(data);
  }

  Stream<List<AdvanceRequest>> getAdvanceRequestsForWorker(String workerId) {
    return _firestore
        .collection('advance_requests')
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AdvanceRequest.fromMap(doc.data())).toList());
  }

  Stream<List<AdvanceRequest>> getAdvanceRequestsForOwner() {
    if (_uid == null) return Stream.value([]);
    return _firestore
        .collection('advance_requests')
        .where('businessId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AdvanceRequest.fromMap(doc.data())).toList());
  }

  Future<void> updateAdvanceStatus(String requestId, AdvanceStatus status) async {
    await _firestore.collection('advance_requests').doc(requestId).update({'status': status.name});
  }

  // PROJECTS (SITES)
  Stream<List<Project>> getProjects() {
    if (_uid == null) return Stream.value([]);
    return _firestore
        .collection('projects')
        .where('businessId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList());
  }

  Future<void> addProject(Project project) async {
    if (_uid == null) return;
    final data = project.toMap();
    data['businessId'] = _uid;
    await _firestore.collection('projects').doc(project.id).set(data);
  }

  Future<void> deleteProject(String projectId) async {
    await _firestore.collection('projects').doc(projectId).delete();
  }

  Future<void> updateWorkerRating(String workerId, double rating) async {
    await _firestore.collection('workers').doc(workerId).update({'rating': rating});
  }

  Future<void> assignWorkerToProject(String workerId, String? projectId) async {
    await _firestore.collection('workers').doc(workerId).update({'projectId': projectId});
  }
}
