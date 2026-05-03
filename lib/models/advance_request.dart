
enum AdvanceStatus { pending, approved, rejected }

class AdvanceRequest {
  final String id;
  final String workerId;
  final String workerName;
  final double amount;
  final DateTime date;
  final String? note;
  final AdvanceStatus status;
  final String? businessId;

  AdvanceRequest({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.amount,
    required this.date,
    this.note,
    this.status = AdvanceStatus.pending,
    this.businessId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'workerName': workerName,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'status': status.name,
      'businessId': businessId,
    };
  }

  factory AdvanceRequest.fromMap(Map<String, dynamic> map) {
    return AdvanceRequest(
      id: map['id'] ?? '',
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? 'Worker',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'],
      status: AdvanceStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => AdvanceStatus.pending),
      businessId: map['businessId'],
    );
  }
}
