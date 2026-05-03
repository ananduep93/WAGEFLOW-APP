import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WageFlow Pro Privacy Policy',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text('Effective Date: April 30, 2026', style: TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            _buildSection('1. Introduction', 
              'WageFlow Pro ("we", "us", or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.'),
            _buildSection('2. Information We Collect', 
              'We collect personal information that you provide to us, including:\n'
              '• Business owner name and email address.\n'
              '• Worker names, phone numbers, and daily wage rates.\n'
              '• Attendance records and payment history.\n'
              '• Project and site details.'),
            _buildSection('3. How We Use Your Information', 
              'The information we collect is used solely for the purpose of construction management, including:\n'
              '• Tracking labor attendance and calculating wages.\n'
              '• Facilitating payment records and financial reporting.\n'
              '• Sending notifications via WhatsApp (with your consent).'),
            _buildSection('4. Data Security', 
              'We use industry-standard encryption and Firebase security protocols to protect your data. However, no method of transmission over the internet is 100% secure.'),
            _buildSection('5. Account Deletion', 
              'Users have the right to delete their accounts and all associated data at any time through the Settings menu in the application.'),
            _buildSection('6. Contact Us', 
              'If you have any questions about this Privacy Policy, please contact us at: support@wageflowpro.com'),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 WageFlow Pro. All rights reserved.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
        ],
      ),
    );
  }
}
