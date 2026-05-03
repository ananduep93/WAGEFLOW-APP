import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/firebase_provider.dart';
import '../../models/advance_request.dart';
import '../../models/payment.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';

class AdvanceRequestsScreen extends ConsumerWidget {
  const AdvanceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(ownerAdvanceRequestsProvider);

    return requestsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text('No advance requests found.', style: TextStyle(color: Colors.grey)));
        }

        final sorted = [...list]..sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final r = sorted[index];
            return _buildRequestCard(context, ref, r);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildRequestCard(BuildContext context, WidgetRef ref, AdvanceRequest r) {
    Color statusColor = Colors.orange;
    if (r.status == AdvanceStatus.approved) statusColor = Colors.green;
    if (r.status == AdvanceStatus.rejected) statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.workerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₹${r.amount.toStringAsFixed(0)}', 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(r.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (r.note != null && r.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text('Note: ${r.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ],
            const SizedBox(height: 16),
            if (r.status == AdvanceStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleStatusUpdate(ref, r, AdvanceStatus.rejected),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleStatusUpdate(ref, r, AdvanceStatus.approved),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    r.status.name.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStatusUpdate(WidgetRef ref, AdvanceRequest request, AdvanceStatus status) async {
    final service = ref.read(firebaseServiceProvider);
    await service.updateAdvanceStatus(request.id, status);
    
    if (status == AdvanceStatus.approved) {
      // Create an automatic payment record
      final payment = Payment(
        id: const Uuid().v4(),
        workerId: request.workerId,
        amount: request.amount,
        date: DateTime.now(),
        method: PaymentMethod.cash, // Default to cash for advances
        note: 'Advance Approved: ${request.note ?? ""}',
        businessId: request.businessId,
      );
      await service.addPayment(payment);
    }
  }
}
