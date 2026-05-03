import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/firebase_provider.dart';

class OwnerStats {
  final double totalEarned;
  final double totalPaid;
  final double totalPending;
  final double todayExpense;

  OwnerStats({
    required this.totalEarned,
    required this.totalPaid,
    required this.totalPending,
    required this.todayExpense,
  });
}

final ownerStatsCalculationProvider = Provider<OwnerStats>((ref) {
  final attendance = ref.watch(allAttendanceStreamProvider).value ?? [];
  final payments = ref.watch(paymentsStreamProvider).value ?? [];
  
  double earned = 0;
  double paid = 0;
  double today = 0;
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  for (var a in attendance) {
    earned += a.calculatedWage;
    // Check if attendance is for today
    if (a.date.year == todayStart.year && 
        a.date.month == todayStart.month && 
        a.date.day == todayStart.day) {
      today += a.calculatedWage;
    }
  }

  for (var p in payments) {
    paid += p.amount;
  }

  return OwnerStats(
    totalEarned: earned,
    totalPaid: paid,
    totalPending: earned - paid,
    todayExpense: today,
  );
});
