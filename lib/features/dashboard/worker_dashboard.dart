import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/firebase_provider.dart';
import '../../models/worker.dart';
import '../../models/attendance.dart';
import '../../models/payment.dart';
import '../../models/advance_request.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class WorkerDashboard extends ConsumerWidget {
  const WorkerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(myWorkerRecordProvider);
    
    return workerAsync.when(
      data: (worker) {
        if (worker == null) {
          return _buildNotLinkedState();
        }
        
        final attendanceAsync = ref.watch(attendanceStreamProvider(worker.id));
        final paymentsAsync = ref.watch(paymentsForWorkerStreamProvider(worker.id));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWorkerSummary(context, ref, worker, attendanceAsync.value, paymentsAsync.value),
              const SizedBox(height: 32),
              const Text('My Attendance History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildAttendanceList(attendanceAsync),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Advance Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => _showRequestAdvanceDialog(context, ref, worker),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Request New'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAdvanceRequestsList(ref, worker.id),
              const SizedBox(height: 32),
              const Text('Recent Payments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildPaymentsList(paymentsAsync),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildWorkerSummary(BuildContext context, WidgetRef ref, Worker worker, List<Attendance>? attendance, List<Payment>? payments) {
    double totalEarned = attendance
            ?.where((a) => a.workerId == worker.id)
            .fold(0.0, (sum, item) => sum! + item.calculatedWage) ??
        0.0;
    double totalPaid = payments
            ?.where((p) => p.workerId == worker.id)
            .fold(0.0, (sum, item) => sum! + item.amount) ??
        0.0;
    double pending = totalEarned - totalPaid;

    final projectsAsync = ref.watch(allProjectsStreamProvider);
    String? currentProjectName;
    if (worker.projectId != null) {
      try {
        projectsAsync.whenData((projects) {
          final matches = projects.where((p) => p.id == worker.projectId);
          currentProjectName = matches.isNotEmpty ? matches.first.name : null;
        });
      } catch (e) {
        debugPrint('Project lookup error: $e');
        currentProjectName = 'Syncing...';
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF303F9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (worker.projectId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.architecture, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Assigned Site: ${currentProjectName ?? "..."}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Total Earned This Month',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalEarned.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Paid', '₹${totalPaid.toStringAsFixed(0)}', Icons.check_circle_outline),
              _buildSummaryItem('Pending', '₹${pending.toStringAsFixed(0)}', Icons.timer_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildAttendanceList(AsyncValue<List<Attendance>> attendanceAsync) {
    return attendanceAsync.when(
      data: (list) {
        final sortedList = [...list]..sort((a, b) => b.date.compareTo(a.date));
        if (sortedList.isEmpty) return const Text('No attendance recorded yet.', style: TextStyle(color: Colors.grey));
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedList.length > 5 ? 5 : sortedList.length,
          itemBuilder: (context, index) {
            final a = sortedList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('${a.date.day}/${a.date.month}/${a.date.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(a.status.name.toUpperCase(), style: TextStyle(color: a.status == AttendanceStatus.present ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildPaymentsList(AsyncValue<List<Payment>> paymentsAsync) {
    return paymentsAsync.when(
      data: (list) {
        final sortedList = [...list]..sort((a, b) => b.date.compareTo(a.date));
        if (sortedList.isEmpty) return const Text('No payments recorded yet.', style: TextStyle(color: Colors.grey));
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedList.length > 5 ? 5 : sortedList.length,
          itemBuilder: (context, index) {
            final p = sortedList[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
              title: Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.date.day}/${p.date.month} • ${p.method.name.toUpperCase()}'),
                  if (p.note != null && p.note!.isNotEmpty)
                    Text('Note: ${p.note}', style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontStyle: FontStyle.italic)),
                ],
              ),
            );
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildNotLinkedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'Account Not Linked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ask your business owner to add you using your email address so you can see your attendance and wages.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceRequestsList(WidgetRef ref, String workerId) {
    final requestsAsync = ref.watch(advanceRequestsForWorkerProvider(workerId));
    
    return requestsAsync.when(
      data: (list) {
        if (list.isEmpty) return const Text('No requests yet.', style: TextStyle(color: Colors.grey));
        final sorted = [...list]..sort((a, b) => b.date.compareTo(a.date));
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length > 3 ? 3 : sorted.length,
          itemBuilder: (context, index) {
            final r = sorted[index];
            Color statusColor = Colors.orange;
            if (r.status == AdvanceStatus.approved) statusColor = Colors.green;
            if (r.status == AdvanceStatus.rejected) statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('₹${r.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('dd MMM').format(r.date)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    r.status.name.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => Text('Error: $e'),
    );
  }

  void _showRequestAdvanceDialog(BuildContext context, WidgetRef ref, dynamic worker) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Advance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), prefixText: '₹'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (Optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty) {
                final request = AdvanceRequest(
                  id: const Uuid().v4(),
                  workerId: worker.id,
                  workerName: worker.name,
                  amount: double.parse(amountController.text),
                  date: DateTime.now(),
                  note: noteController.text,
                  businessId: worker.businessId,
                );
                await ref.read(firebaseServiceProvider).createAdvanceRequest(request);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}
