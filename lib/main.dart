import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_ai/core/theme/app_theme.dart';
import 'package:food_ai/core/router/app_router.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/core/config/env.dart';
import 'package:food_ai/core/auth/auth_notifier.dart';
import 'package:food_ai/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase(supabaseConfig);
  final authNotifier = isSupabaseConfigured ? AuthNotifier() : null;
  runApp(
    ProviderScope(
      child: FoodAiApp(authNotifier: authNotifier),
    ),
  );
}

class FoodAiApp extends StatelessWidget {
  const FoodAiApp({super.key, this.authNotifier});

  final AuthNotifier? authNotifier;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: createAppRouter(authNotifier),
    );
  }
}
