import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/auth/auth_provider.dart';
import 'core/providers/profile_provider.dart';
import 'features/onboarding/role_selection_screen.dart';
import 'models/worker.dart';
import 'firebase_options.dart';
import 'models/attendance.dart';
import 'models/payment.dart';

Future<void> _initApp() async {
  await Future.delayed(const Duration(milliseconds: 500));
  await Hive.initFlutter();
  
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(WorkerAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AttendanceAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AttendanceStatusAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PaymentAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(PaymentMethodAdapter());

  await Hive.openBox<Worker>('workers');
  await Hive.openBox<Attendance>('attendance');
  await Hive.openBox<Payment>('payments');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: WageFlowApp(),
    ),
  );
}

class WageFlowApp extends ConsumerWidget {
  const WageFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'WageFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return FutureBuilder(
              future: _initApp(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return const LoginScreen();
                }
                return const SplashScreen();
              },
            );
          }

          // User is logged in, now check for profile/role
          final profileAsync = ref.watch(userProfileProvider);
          return profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const RoleSelectionScreen();
              }
              return const DashboardScreen();
            },
            loading: () => const SplashScreen(),
            error: (e, stack) => Scaffold(body: Center(child: Text('Profile Error: $e'))),
          );
        },
        loading: () => const SplashScreen(),
        error: (e, stack) => Scaffold(body: Center(child: Text('Auth Error: $e'))),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 150,
            ),
            const SizedBox(height: 24),
            Text(
              'WageFlow',
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            const Text('Loading your workspace...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
