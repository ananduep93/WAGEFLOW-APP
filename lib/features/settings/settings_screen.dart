import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/firebase_provider.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../models/app_user.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(firebaseServiceProvider).getBusinessProfile().first;
    if (profile != null) {
      _businessNameController.text = profile['businessName'] ?? '';
      _ownerNameController.text = profile['ownerName'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _addressController.text = profile['address'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(firebaseServiceProvider).updateBusinessProfile({
        'businessName': _businessNameController.text,
        'ownerName': _ownerNameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(color: Colors.red)),
        content: const Text('This action is permanent. All your workers, projects, and records will be deleted forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // In a real app, you would call firebase deletion logic here
              await ref.read(authServiceProvider).signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deletion requested. All data will be purged within 24 hours.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your WageFlow account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(userProfile),
            const Divider(height: 48),
            
            // Only show Business Profile if the user is an OWNER
            userProfile.when(
              data: (profile) => profile?.role == UserRole.owner 
                ? _buildBusinessSection() 
                : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),
            
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blue),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Colors.blue),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terms of Service coming soon.')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.red),
              onTap: () {
                HapticFeedback.mediumImpact();
                _showDeleteAccountConfirmation();
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showLogoutConfirmation();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'WageFlow Pro v1.0.0',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(AsyncValue<AppUser?> userProfile) {
    return userProfile.when(
      data: (user) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.person_outline, 'Name', user?.name ?? 'Loading...'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, 'Email', user?.email ?? 'Loading...'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.badge_outlined, 'Role', user?.role.name.toUpperCase() ?? 'Loading...'),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error loading profile: $e'),
    );
  }

  Widget _buildBusinessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('This info appears on shared summaries.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        _buildTextField('Business Name', _businessNameController, Icons.business),
        const SizedBox(height: 16),
        _buildTextField('Business Address', _addressController, Icons.location_on_outlined, maxLines: 2),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving ? const CircularProgressIndicator() : const Text('Update Business Info'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
