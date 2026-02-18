import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_ai/services/auth_service.dart';
import 'package:food_ai/services/profile_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) => authStateChanges);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.session?.user ?? currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final currentProfileProvider = FutureProvider<ProfileRecord?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return getProfile(user.id);
});
