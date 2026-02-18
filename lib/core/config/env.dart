import 'package:food_ai/core/config/supabase_config.dart';

/// URL и anon key задаются через dart-define:
/// flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
/// или подставьте значения ниже для разработки (не коммитьте ключи).
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);
const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

SupabaseConfig get supabaseConfig => SupabaseConfig(url: supabaseUrl, anonKey: supabaseAnonKey);

/// Ключ OpenRouter для ИИ. Задать через dart-define:
/// flutter run --dart-define=OPENROUTER_API_KEY=sk-or-v1-...
const String openRouterApiKey = String.fromEnvironment(
  'OPENROUTER_API_KEY',
  defaultValue: '',
);

bool get isAiConfigured => openRouterApiKey.isNotEmpty;
