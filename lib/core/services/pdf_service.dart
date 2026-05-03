import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../models/worker.dart';
import '../../models/attendance.dart';
import '../../models/payment.dart';

class PdfService {
  static Future<void> generateWorkerReport(
    Worker worker,
    List<Attendance> attendance,
    List<Payment> payments,
  ) async {
    final pdf = pw.Document();

    final totalEarned = attendance.fold(0.0, (sum, dynamic item) => sum + item.calculatedWage);
    final totalPaid = payments.fold(0.0, (sum, dynamic item) => sum + item.amount);
    final pending = totalEarned - totalPaid;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('WageFlow Pro - Worker Statement')),
              pw.SizedBox(height: 20),
              pw.Text('Worker Name: ${worker.name}'),
              pw.Text('Phone: ${worker.phone}'),
              pw.Text('Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Financial Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Earned:'),
                  pw.Text('Rs. ${totalEarned.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Paid:'),
                  pw.Text('Rs. ${totalPaid.toStringAsFixed(2)}'),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Balance Pending:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${pending.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Text('Attendance Log (Last 30 Days)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<dynamic>>[
                  <String>['Date', 'Status', 'Wage'],
                  ...attendance.map((dynamic a) {
                    return <String>[
                      DateFormat('dd/MM/yyyy').format(a.date),
                      a.status.name.toUpperCase(),
                      'Rs. ${a.calculatedWage.toStringAsFixed(0)}'
                    ];
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> shareWorkerReport(
    Worker worker,
    List<Attendance> attendance,
    List<Payment> payments,
  ) async {
    final pdf = pw.Document();

    final totalEarned = attendance.fold(0.0, (sum, dynamic item) => sum + item.calculatedWage);
    final totalPaid = payments.fold(0.0, (sum, dynamic item) => sum + item.amount);
    final pending = totalEarned - totalPaid;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('WageFlow Pro - Worker Statement')),
              pw.SizedBox(height: 20),
              pw.Text('Worker Name: ${worker.name}'),
              pw.Text('Phone: ${worker.phone}'),
              pw.Text('Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Financial Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Earned:'),
                  pw.Text('Rs. ${totalEarned.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Paid:'),
                  pw.Text('Rs. ${totalPaid.toStringAsFixed(2)}'),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Balance Pending:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rs. ${pending.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Text('Attendance Log (Last 30 Days)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<dynamic>>[
                  <String>['Date', 'Status', 'Wage'],
                  ...attendance.map((dynamic a) {
                    return <String>[
                      DateFormat('dd/MM/yyyy').format(a.date),
                      a.status.name.toUpperCase(),
                      'Rs. ${a.calculatedWage.toStringAsFixed(0)}'
                    ];
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    
    // Instead of direct sharing which can hang, we open the PDF Preview
    // The preview screen has a built-in share button that is 100% reliable
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${worker.name}_Report',
    );
  }
}
