import 'package:food_ai/core/config/supabase_config.dart';
import 'package:food_ai/core/config/env.local.dart' as env_local;

const String _supabaseUrlEnv = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);
const String _supabaseAnonKeyEnv = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

String get supabaseUrl =>
    env_local.localSupabaseUrl.isNotEmpty ? env_local.localSupabaseUrl : _supabaseUrlEnv;

String get supabaseAnonKey =>
    env_local.localSupabaseAnonKey.isNotEmpty ? env_local.localSupabaseAnonKey : _supabaseAnonKeyEnv;

SupabaseConfig get supabaseConfig =>
    SupabaseConfig(url: supabaseUrl, anonKey: supabaseAnonKey);

const String _openRouterApiKeyEnv = String.fromEnvironment(
  'OPENROUTER_API_KEY',
  defaultValue: '',
);

String get openRouterApiKey => env_local.localOpenRouterApiKey.isNotEmpty
    ? env_local.localOpenRouterApiKey
    : _openRouterApiKeyEnv;

bool get isAiConfigured => openRouterApiKey.isNotEmpty;
