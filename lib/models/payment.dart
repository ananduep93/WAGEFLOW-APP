import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 3)
enum PaymentMethod {
  @HiveField(0)
  cash,
  @HiveField(1)
  upi,
  @HiveField(2)
  bank
}

@HiveType(typeId: 4)
class Payment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String workerId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final PaymentMethod method;

  @HiveField(5)
  final String? note; // Note/message field

  @HiveField(6)
  final String? businessId; // Link to Owner

  @HiveField(7)
  final String? projectId; // Link to Site

  Payment({
    required this.id,
    required this.workerId,
    required this.amount,
    required this.date,
    required this.method,
    this.note,
    this.businessId,
    this.projectId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method.name,
      'note': note,
      'businessId': businessId,
      'projectId': projectId,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      workerId: map['workerId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: DateTime.parse(map['date']),
      method: PaymentMethod.values.byName(map['method']),
      note: map['note'],
      businessId: map['businessId'],
      projectId: map['projectId'],
    );
  }
}
