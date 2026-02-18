import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_ai/services/supabase_service.dart';

/// Уведомляет роутер об изменении авторизации для редиректа.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    if (isSupabaseConfigured) {
      _user = supabase.auth.currentUser;
      _sub = supabase.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        notifyListeners();
      });
    }
  }

  User? _user;
  StreamSubscription<AuthState>? _sub;

  User? get user => _user;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
