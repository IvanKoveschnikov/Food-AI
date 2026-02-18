import 'package:food_ai/services/supabase_service.dart';

class ProfileRecord {
  ProfileRecord({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProfileRecord.fromMap(Map<String, dynamic> map) {
    return ProfileRecord(
      id: map['id'] as String,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

Future<ProfileRecord?> getProfile(String userId) async {
  if (!isSupabaseConfigured) return null;
  final res = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
  return res != null ? ProfileRecord.fromMap(res as Map<String, dynamic>) : null;
}

Future<void> updateProfile(String userId, {String? displayName, String? avatarUrl}) async {
  final map = <String, dynamic>{};
  if (displayName != null) map['display_name'] = displayName;
  if (avatarUrl != null) map['avatar_url'] = avatarUrl;
  if (map.isEmpty) return;
  await supabase.from('profiles').update(map).eq('id', userId);
}
