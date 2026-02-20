import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_ai/services/supabase_service.dart';

User? get currentUser =>
    isSupabaseConfigured ? supabase.auth.currentUser : null;

Stream<AuthState> get authStateChanges => isSupabaseConfigured
    ? supabase.auth.onAuthStateChange
    : const Stream.empty();

Future<AuthResponse> signUp({
  required String email,
  required String password,
  String? displayName,
}) async {
  if (!isSupabaseConfigured) {
    throw Exception(
      'Supabase не настроен. Укажите SUPABASE_URL и SUPABASE_ANON_KEY при запуске.',
    );
  }
  return supabase.auth.signUp(
    email: email,
    password: password,
    data: displayName != null ? {'display_name': displayName} : null,
  );
}

Future<AuthResponse> signInWithPassword({
  required String email,
  required String password,
}) async {
  if (!isSupabaseConfigured) {
    throw Exception(
      'Supabase не настроен. Укажите SUPABASE_URL и SUPABASE_ANON_KEY при запуске.',
    );
  }
  return supabase.auth.signInWithPassword(email: email, password: password);
}

Future<void> sendPasswordResetEmail(String email) async {
  if (!isSupabaseConfigured) {
    throw Exception('Supabase не настроен');
  }
  await supabase.auth.resetPasswordForEmail(email);
}

Future<void> signOut() async {
  if (isSupabaseConfigured) await supabase.auth.signOut();
}
