import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/firebase_provider.dart';
import '../workers/worker_list_screen.dart';
import '../workers/worker_detail_screen.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/services/pdf_service.dart';
import 'package:uuid/uuid.dart';
import '../../models/attendance.dart';

class OwnerDashboard extends ConsumerWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(workersStreamProvider);
    final stats = ref.watch(ownerStatsCalculationProvider);

    return workersAsync.when(
      data: (workers) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(workersStreamProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryGrid(context, ref, workers, stats),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Workers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerListScreen()));
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (workers.isEmpty)
                  _buildEmptyState()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: workers.length > 5 ? 5 : workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      return _buildWorkerCard(context, worker, ref);
                    },
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, WidgetRef ref, List<dynamic> workers, OwnerStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Today Expense', '₹${NumberFormat('#,###').format(stats.todayExpense)}', Icons.today, Colors.blue),
        _buildStatCard('Total Paid', '₹${NumberFormat('#,##,###').format(stats.totalPaid)}', Icons.check_circle, AppColors.paid),
        _buildStatCard('Total Pending', '₹${NumberFormat('#,##,###').format(stats.totalPending)}', Icons.pending_actions, AppColors.pending),
        _buildStatCard('Workers', workers.length.toString(), Icons.people, AppColors.primary),
        _buildActionCard(context, 'Mark Holiday', Icons.beach_access, Colors.orange, () => _markHolidayForAll(context, ref, workers)),
        _buildActionCard(context, 'Business Report', Icons.picture_as_pdf, Colors.red, () => _generateFullReport(context, ref, workers)),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext context, dynamic worker, WidgetRef ref) {
    // Get worker-specific stats for the card
    final attendance = ref.watch(attendanceStreamProvider(worker.id)).value ?? [];
    final payments = ref.watch(paymentsForWorkerStreamProvider(worker.id)).value ?? [];
    
    double earned = attendance.fold(0.0, (sum, item) => sum + item.calculatedWage);
    double paid = payments.fold(0.0, (sum, item) => sum + item.amount);
    double pending = earned - paid;

    return Hero(
      tag: 'worker_${worker.id}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(worker.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Pending: ₹${NumberFormat('#,###').format(pending)}', 
            style: TextStyle(color: pending > 0 ? AppColors.pending : Colors.grey)),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => WorkerDetailScreen(worker: worker)));
          },
        ),
      ),
    );
  }

  Future<void> _markHolidayForAll(BuildContext context, WidgetRef ref, List<dynamic> workers) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Holiday for All?'),
        content: const Text('This will mark today as a Holiday (Absent/Unpaid) for all your workers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );

    if (confirmed == true) {
      for (var worker in workers) {
        final attendance = Attendance(
          id: const Uuid().v4(),
          workerId: worker.id,
          date: DateTime.now(),
          status: AttendanceStatus.absent,
          calculatedWage: 0,
        );
        await ref.read(firebaseServiceProvider).markAttendance(attendance);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Holiday marked for everyone!')));
      }
    }
  }

  Future<void> _generateFullReport(BuildContext context, WidgetRef ref, List<dynamic> workers) async {
    // For simplicity, we'll generate the report for the first worker or show a selector
    // In a real app, you'd show a list to pick which worker's report to generate
    if (workers.isEmpty) return;
    
    final worker = workers.first;
    final attendance = ref.read(attendanceStreamProvider(worker.id)).value ?? [];
    final payments = ref.read(paymentsForWorkerStreamProvider(worker.id)).value ?? [];
    
    await PdfService.generateWorkerReport(worker, attendance, payments);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.person_add_outlined, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            const Text('No workers yet. Add your team to start.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
