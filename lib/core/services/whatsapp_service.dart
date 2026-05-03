import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class WhatsAppService {
  static Future<void> sendMessage({
    required String phone,
    required String message,
  }) async {
    // Sanitize phone number (ensure it has country code)
    String sanitizedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (sanitizedPhone.length == 10) {
      sanitizedPhone = '91$sanitizedPhone'; // Default to India if no country code
    }

    final url = Uri.parse('whatsapp://send?phone=$sanitizedPhone&text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Fallback for web or if scheme not supported
        final webUrl = Uri.parse('https://wa.me/$sanitizedPhone?text=${Uri.encodeComponent(message)}');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

  static String formatAttendanceMessage(String workerName, String date, String status, double wage) {
    return '''*WageFlow Pro Attendance Alert* 👷‍♂️✅

Hi *$workerName*,
Your attendance for *$date* has been marked.

📍 *Status:* ${status.toUpperCase()}
💰 *Daily Wage:* ₹$wage

Thank you for your hard work!''';
  }

  static String formatPaymentMessage(String workerName, double amount, String date, String method, String? note) {
    String noteText = note != null && note.isNotEmpty ? '\n📝 *Note:* $note' : '';
    return '''*WageFlow Pro Payment Received* 💸✨

Hi *$workerName*,
A payment has been recorded for you.

💰 *Amount:* ₹$amount
📅 *Date:* $date
💳 *Method:* ${method.toUpperCase()}$noteText

Please check your dashboard for details.''';
  }
}
