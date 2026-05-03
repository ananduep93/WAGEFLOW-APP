import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/worker.dart';
import '../../models/attendance.dart';
import '../../models/payment.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/firebase_provider.dart';
import '../auth/auth_provider.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/whatsapp_service.dart';

class WorkerDetailScreen extends ConsumerStatefulWidget {
  final Worker worker;
  const WorkerDetailScreen({super.key, required this.worker});

  @override
  ConsumerState<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends ConsumerState<WorkerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update FAB when tab changes
    });
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(attendanceStreamProvider(widget.worker.id));
    final paymentsAsync = ref.watch(paymentsForWorkerStreamProvider(widget.worker.id));
    final projectsAsync = ref.watch(allProjectsStreamProvider);

    String? currentProjectName;
    if (widget.worker.projectId != null) {
      projectsAsync.whenData((projects) {
        final matches = projects.where((p) => p.id == widget.worker.projectId);
        currentProjectName = matches.isNotEmpty ? matches.first.name : null;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worker.name),
        actions: [
          IconButton(
            onPressed: () => _shareWorkerDetails(attendanceAsync.value, paymentsAsync.value),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: () => _showEditWorkerDialog(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWorkerStats(attendanceAsync.value, paymentsAsync.value, currentProjectName),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Attendance', icon: Icon(Icons.calendar_today_outlined)),
              Tab(text: 'Payments', icon: Icon(Icons.payments_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceTab(attendanceAsync),
                _buildPaymentsTab(paymentsAsync),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
        ? FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showMarkAttendanceDialog(context);
            },
            label: const Text('Mark Today'),
            icon: const Icon(Icons.check),
          )
        : FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAddPaymentDialog(context);
            },
            label: const Text('Add Payment'),
            icon: const Icon(Icons.add),
          ),
    );
  }

  Widget _buildWorkerStats(List<Attendance>? attendance, List<Payment>? payments, String? currentProjectName) {
    // Filter attendance and payments to only count those belonging to THIS owner
    
    double totalEarned = attendance
            ?.where((a) => a.workerId == widget.worker.id)
            .fold(0.0, (sum, item) => sum! + item.calculatedWage) ??
        0.0;
    double totalPaid = 0;
    if (payments != null) {
      for (var p in payments) {
        if (p.workerId == widget.worker.id) {
          totalPaid += p.amount;
        }
      }
    }
    double pending = totalEarned - totalPaid;

    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => ref.read(firebaseServiceProvider).updateWorkerRating(widget.worker.id, index + 1.0),
                icon: Icon(
                  index < widget.worker.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Earned', '₹${NumberFormat('#,###').format(totalEarned)}', Colors.blue),
              _buildStatItem('Paid', '₹${NumberFormat('#,###').format(totalPaid)}', AppColors.paid),
              _buildStatItem('Pending', '₹${NumberFormat('#,###').format(pending)}', AppColors.pending),
            ],
          ),
          if (widget.worker.projectId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.architecture, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text('Assigned Site: ${currentProjectName ?? "..."}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddPaymentDialog(context),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('PAY MONEY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAttendanceTab(AsyncValue<List<Attendance>> attendanceAsync) {
    return attendanceAsync.when(
      data: (attendanceList) {
        final attendanceMap = {for (var a in attendanceList) DateTime(a.date.year, a.date.month, a.date.day): a};

        return SingleChildScrollView(
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final normalizedDay = DateTime(day.year, day.month, day.day);
                    if (attendanceMap.containsKey(normalizedDay)) {
                      final status = attendanceMap[normalizedDay]!.status;
                      Color color = Colors.green;
                      if (status == AttendanceStatus.halfDay) color = Colors.orange;
                      if (status == AttendanceStatus.absent) color = Colors.red;
                      
                      return Center(
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.3), shape: BoxShape.circle),
                          child: Center(child: Text(day.day.toString())),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(color: Colors.green, label: 'Present'),
                    SizedBox(width: 16),
                    _LegendItem(color: Colors.orange, label: 'Half Day'),
                    SizedBox(width: 16),
                    _LegendItem(color: Colors.red, label: 'Absent'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPaymentsTab(AsyncValue<List<Payment>> paymentsAsync) {
    return paymentsAsync.when(
      data: (payments) {
        // Sort payments by date (newest first)
        final sortedPayments = [...payments]..sort((a, b) => b.date.compareTo(a.date));
        
        if (sortedPayments.isEmpty) return const Center(child: Text('No payments recorded yet.'));
        return ListView.builder(
          itemCount: sortedPayments.length,
          itemBuilder: (context, index) {
            final payment = sortedPayments[index];
            return Dismissible(
              key: Key(payment.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Payment?'),
                    content: const Text('Are you sure you want to remove this payment record?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                ref.read(firebaseServiceProvider).deletePayment(payment.id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment deleted')));
              },
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.currency_rupee)),
                title: Text('₹${payment.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(payment.date)),
                    if (payment.note != null && payment.note!.isNotEmpty)
                      Text(payment.note!, style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontStyle: FontStyle.italic)),
                  ],
                ),
                trailing: Text(payment.method.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  void _showMarkAttendanceDialog(BuildContext context) {
    final projectsAsync = ref.watch(allProjectsStreamProvider);
    String? selectedProjectId;
    bool notifyWhatsApp = true;

    showStatefulDialog(
      context: context,
      builder: (context, setState) => AlertDialog(
        title: const Text('Mark Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            projectsAsync.when(
              data: (projects) => DropdownButtonFormField<String>(
                initialValue: selectedProjectId ?? widget.worker.projectId,
                decoration: const InputDecoration(labelText: 'Select Site', border: OutlineInputBorder()),
                items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (val) => setState(() => selectedProjectId = val),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading sites'),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Notify via WhatsApp', style: TextStyle(fontSize: 14)),
              value: notifyWhatsApp,
              onChanged: (val) => setState(() => notifyWhatsApp = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Full Day (Present)'),
              onTap: () => _markAttendance(AttendanceStatus.present, selectedProjectId, notifyWhatsApp),
            ),
            ListTile(
              leading: const Icon(Icons.timelapse, color: Colors.orange),
              title: const Text('Half Day'),
              onTap: () => _markAttendance(AttendanceStatus.halfDay, selectedProjectId, notifyWhatsApp),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Absent'),
              onTap: () => _markAttendance(AttendanceStatus.absent, selectedProjectId, notifyWhatsApp),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAttendance(AttendanceStatus status, String? projectId, bool notifyWhatsApp) async {
    Navigator.pop(context);
    double wage = widget.worker.wageRate;
    if (status == AttendanceStatus.halfDay) wage /= 2;
    if (status == AttendanceStatus.absent) wage = 0;

    final attendance = Attendance(
      id: const Uuid().v4(),
      workerId: widget.worker.id,
      date: _selectedDay ?? DateTime.now(),
      status: status,
      calculatedWage: wage,
      projectId: projectId,
    );

    await ref.read(firebaseServiceProvider).markAttendance(attendance);

    if (notifyWhatsApp && widget.worker.phone.isNotEmpty) {
      final dateStr = DateFormat('dd MMM yyyy').format(attendance.date);
      final msg = WhatsAppService.formatAttendanceMessage(
        widget.worker.name, 
        dateStr, 
        status.name, 
        wage
      );
      await WhatsAppService.sendMessage(phone: widget.worker.phone, message: msg);
    }
  }

  void _showAddPaymentDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final projectsAsync = ref.watch(allProjectsStreamProvider);
    String? selectedProjectId;
    bool notifyWhatsApp = true;
    bool isSaving = false;
    
    showStatefulDialog(
      context: context,
      builder: (context, setState) => AlertDialog(
        title: const Text('Pay Money (Add Payment)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              projectsAsync.when(
                data: (projects) => DropdownButtonFormField<String>(
                  initialValue: selectedProjectId ?? widget.worker.projectId,
                  decoration: const InputDecoration(labelText: 'Select Site', border: OutlineInputBorder()),
                  items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (val) => setState(() => selectedProjectId = val),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading sites'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), prefixText: '₹'),
                keyboardType: TextInputType.number,
                enabled: !isSaving,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Message to worker (Optional)', border: OutlineInputBorder(), hintText: 'e.g. Weekly wage, Bonus'),
                maxLines: 2,
                enabled: !isSaving,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Notify via WhatsApp', style: TextStyle(fontSize: 14)),
                value: notifyWhatsApp,
                onChanged: (val) => setState(() => notifyWhatsApp = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                enabled: !isSaving,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : () => Navigator.pop(context), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: isSaving ? null : () async {
              if (amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0) return;

                setState(() => isSaving = true);
                
                try {
                  final ownerUid = ref.read(authServiceProvider).currentUser?.uid;
                  
                  final payment = Payment(
                    id: const Uuid().v4(),
                    workerId: widget.worker.id,
                    amount: amount,
                    date: DateTime.now(),
                    method: PaymentMethod.cash,
                    note: noteController.text.trim(),
                    businessId: ownerUid,
                    projectId: selectedProjectId ?? widget.worker.projectId,
                  );
                  await ref.read(firebaseServiceProvider).addPayment(payment);
                  
                  if (notifyWhatsApp && widget.worker.phone.isNotEmpty) {
                    final dateStr = DateFormat('dd MMM yyyy').format(payment.date);
                    final msg = WhatsAppService.formatPaymentMessage(
                      widget.worker.name, 
                      amount, 
                      dateStr, 
                      payment.method.name, 
                      payment.note
                    );
                    await WhatsAppService.sendMessage(phone: widget.worker.phone, message: msg);
                  }

                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    setState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'))
                    );
                  }
                }
              }
            },
            child: isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  // Helper for stateful dialog
  void showStatefulDialog({required BuildContext context, required Widget Function(BuildContext, StateSetter) builder}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: builder),
    );
  }

  void _showEditWorkerDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.worker.name);
    final phoneController = TextEditingController(text: widget.worker.phone);
    final wageController = TextEditingController(text: widget.worker.wageRate.toString());
    bool isSaving = false;

    showStatefulDialog(
      context: context,
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit Worker Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                enabled: !isSaving,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                enabled: !isSaving,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: wageController,
                decoration: const InputDecoration(labelText: 'Daily Wage (₹)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                enabled: !isSaving,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: isSaving ? null : () async {
              if (nameController.text.isNotEmpty && wageController.text.isNotEmpty) {
                setState(() => isSaving = true);
                final updatedWorker = Worker(
                  id: widget.worker.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  wageRate: double.tryParse(wageController.text) ?? 0,
                  businessId: widget.worker.businessId,
                  email: widget.worker.email,
                );
                await ref.read(firebaseServiceProvider).updateWorker(updatedWorker);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Worker details updated!')));
                }
              }
            },
            child: isSaving ? const CircularProgressIndicator() : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _shareWorkerDetails(List<Attendance>? attendance, List<Payment>? payments) async {
    if (attendance == null || payments == null) return;
    
    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF report...'), duration: Duration(seconds: 1)),
    );
    
    await PdfService.shareWorkerReport(widget.worker, attendance, payments);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
