import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/worker_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/payment_provider.dart';
import '../../core/constants/app_colors.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workers = ref.watch(workerProvider);
    final attendance = ref.watch(attendanceProvider);
    final payments = ref.watch(paymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildReportCard(
            context,
            'Master Attendance Report',
            'Summary of all workers attendance and wages',
            Icons.summarize_outlined,
            () => _generatePDF(workers, attendance, payments),
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            'Monthly Wage Summary',
            'Detailed breakdown of wages for the current month',
            Icons.calendar_month_outlined,
            () {},
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            'Payment Reconciliation',
            'Compare earned vs paid amounts for all workers',
            Icons.account_balance_outlined,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.download),
        onTap: onTap,
      ),
    );
  }

  Future<void> _generatePDF(List workers, List attendance, List payments) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('WageFlow - Attendance Report')),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Worker Name', 'Days Present', 'Total Earned', 'Paid', 'Pending'],
            data: workers.map((worker) {
              final wAttendance = attendance.where((a) => a.workerId == worker.id).toList();
              final wPayments = payments.where((p) => p.workerId == worker.id).toList();
              
              final earned = wAttendance.fold(0.0, (sum, a) => sum + a.calculatedWage);
              final paid = wPayments.fold(0.0, (sum, p) => sum + p.amount);
              
              return [
                worker.name,
                wAttendance.length.toString(),
                'Rs. ${earned.toInt()}',
                'Rs. ${paid.toInt()}',
                'Rs. ${(earned - paid).toInt()}',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
