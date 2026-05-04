import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/profile_provider.dart';
import '../../models/app_user.dart';
import '../onboarding/role_selection_screen.dart';
import '../../core/constants/app_colors.dart';
import 'owner_dashboard.dart';
import 'worker_dashboard.dart';
import '../settings/settings_screen.dart';
import '../workers/worker_list_screen.dart';
import 'advance_requests_screen.dart';
import 'project_list_screen.dart';
import '../../core/providers/firebase_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const RoleSelectionScreen();

        final bool isOwner = profile.role == UserRole.owner;

        return Scaffold(
          appBar: AppBar(
            title: Text(isOwner 
                ? (_selectedIndex == 0 ? 'WageFlow Owner' : (_selectedIndex == 1 ? 'Site Management' : (_selectedIndex == 2 ? 'My Workers' : (_selectedIndex == 3 ? 'Advance Requests' : 'Settings'))))
                : (_selectedIndex == 0 ? 'Worker Portal' : 'Settings')),
          ),
          body: _getBody(isOwner),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              HapticFeedback.heavyImpact();
              setState(() => _selectedIndex = index);
            },
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.black54,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 8,
            items: isOwner 
              ? [
                  const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
                  const BottomNavigationBarItem(icon: Icon(Icons.architecture), label: 'Sites'),
                  const BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Workers'),
                  BottomNavigationBarItem(
                    icon: Badge(
                      label: Text(ref.watch(pendingAdvanceRequestsCountProvider).toString()),
                      isLabelVisible: ref.watch(pendingAdvanceRequestsCountProvider) > 0,
                      child: const Icon(Icons.notifications_active_outlined),
                    ), 
                    label: 'Requests',
                  ),
                  const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
                ]
              : const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'My Wages'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
                ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _getBody(bool isOwner) {
    if (isOwner) {
      switch (_selectedIndex) {
        case 0: return const OwnerDashboard();
        case 1: return const ProjectListScreen();
        case 2: return const WorkerListScreen();
        case 3: return const AdvanceRequestsScreen();
        case 4: return const SettingsScreen();
        default: return const OwnerDashboard();
      }
    } else {
      switch (_selectedIndex) {
        case 0: return const WorkerDashboard();
        case 1: return const SettingsScreen();
        default: return const WorkerDashboard();
      }
    }
  }
}
