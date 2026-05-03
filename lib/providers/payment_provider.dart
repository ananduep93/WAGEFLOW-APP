import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/payment.dart';
import 'package:uuid/uuid.dart';

final paymentProvider = StateNotifierProvider<PaymentNotifier, List<Payment>>((ref) {
  return PaymentNotifier();
});

class PaymentNotifier extends StateNotifier<List<Payment>> {
  PaymentNotifier() : super([]) {
    _loadPayments();
  }

  final _box = Hive.box<Payment>('payments');

  void _loadPayments() {
    state = _box.values.toList();
  }

  Future<void> addPayment(String workerId, double amount, DateTime date, PaymentMethod method, {String? note}) async {
    final payment = Payment(
      id: const Uuid().v4(),
      workerId: workerId,
      amount: amount,
      date: date,
      method: method,
      note: note,
    );
    await _box.put(payment.id, payment);
    state = [...state, payment];
  }
}
