import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_ai/core/config/supabase_config.dart';

bool _isSupabaseConfigured = false;

Future<void> initSupabase(SupabaseConfig config) async {
  if (!config.isConfigured) return;
  await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  _isSupabaseConfigured = true;
}

SupabaseClient get supabase => Supabase.instance.client;

bool get isSupabaseConfigured => _isSupabaseConfigured;
