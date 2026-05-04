import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/firebase_provider.dart';
import '../../models/project.dart';
import '../../core/constants/app_colors.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(allAttendanceStreamProvider);
    final paymentsAsync = ref.watch(allPaymentsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
      body: attendanceAsync.when(
        data: (allAttendance) {
          return paymentsAsync.when(
            data: (allPayments) {
              final projectAttendance = allAttendance.where((a) => a.projectId == project.id).toList();
              final projectPayments = allPayments.where((p) => p.projectId == project.id).toList();

              final totalEarnedByWorkers = projectAttendance.fold(0.0, (sum, a) => sum + a.calculatedWage);
              final totalPaidToWorkers = projectPayments.fold(0.0, (sum, p) => sum + p.amount);
              final hasContract = project.contractAmount != null && project.contractAmount! > 0;
              final profit = (project.contractAmount ?? 0) - totalEarnedByWorkers;

              final workersAsync = ref.watch(workersStreamProvider);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSiteOverviewCard(project, profit, totalEarnedByWorkers),
                    const SizedBox(height: 24),
                    const Text('Project Economics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (hasContract) _buildEconomicsRow('Contract Value', project.contractAmount!, Colors.blue),
                    _buildEconomicsRow('Labor Cost (Earned)', totalEarnedByWorkers, Colors.red),
                    _buildEconomicsRow('Actual Paid', totalPaidToWorkers, Colors.green),
                    const Divider(height: 32),
                    if (hasContract) _buildEconomicsRow('Net Profit (Estimated)', profit, profit >= 0 ? Colors.green : Colors.red, isBold: true),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Site Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: () => _showAssignWorkerDialog(context, ref),
                          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                          label: const Text('Assign Worker'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    workersAsync.when(
                      data: (workers) {
                        final projectWorkers = workers.where((w) => w.projectId == project.id).toList();
                        if (projectWorkers.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Text('No workers assigned to this site', style: TextStyle(color: Colors.grey))),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: projectWorkers.length,
                          itemBuilder: (context, index) {
                            final worker = projectWorkers[index];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text(worker.name[0])),
                                title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(worker.phone ?? 'No phone'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
                                  onPressed: () => ref.read(firebaseServiceProvider).assignWorkerToProject(worker.id, null),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 32),
                    const Text('Project Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (hasContract) ...[
                      LinearProgressIndicator(
                        value: (totalEarnedByWorkers / project.contractAmount!).clamp(0, 1),
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.primary,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Text('${((totalEarnedByWorkers / project.contractAmount!) * 100).toStringAsFixed(1)}% of budget spent on labor', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ] else
                      const Text('Budget not set for this project', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAssignWorkerDialog(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(workersStreamProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Worker to Site'),
        content: SizedBox(
          width: double.maxFinite,
          child: workersAsync.when(
            data: (workers) {
              final unassignedWorkers = workers.where((w) => w.projectId == null || w.projectId != project.id).toList();
              if (unassignedWorkers.isEmpty) return const Text('No other workers available to assign.');
              
              return ListView.builder(
                shrinkWrap: true,
                itemCount: unassignedWorkers.length,
                itemBuilder: (context, index) {
                  final worker = unassignedWorkers[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(worker.name[0])),
                    title: Text(worker.name),
                    subtitle: Text(worker.projectId != null ? 'Currently at another site' : 'Available'),
                    onTap: () {
                      ref.read(firebaseServiceProvider).assignWorkerToProject(worker.id, project.id);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildSiteOverviewCard(Project project, double profit, double laborCost) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.architecture, color: Colors.white, size: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(project.contractAmount != null ? (profit >= 0 ? 'Profitable' : 'Loss') : 'Labor Tracker', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(project.contractAmount != null ? 'Total Estimated Profit' : 'Total Labor Cost', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('₹${NumberFormat('#,###').format(project.contractAmount != null ? profit : laborCost)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(project.location, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEconomicsRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${NumberFormat('#,###').format(value)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
