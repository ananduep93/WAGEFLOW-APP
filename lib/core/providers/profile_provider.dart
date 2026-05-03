import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../features/auth/auth_provider.dart';

final userProfileProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;
  
  return await ref.read(authServiceProvider).getUserProfile(authState.uid);
});
