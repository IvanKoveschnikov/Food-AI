import 'package:food_ai/services/supabase_service.dart';

class DishRecord {
  DishRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    this.imageUrl,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String date;
  final String? imageUrl;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DishRecord.fromMap(Map<String, dynamic> map) {
    return DishRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      date: map['date'] as String,
      imageUrl: map['image_url'] as String?,
      description: map['description'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}

Future<List<DishRecord>> getDishesForDate(String userId, String date) async {
  if (!isSupabaseConfigured) return [];
  final res = await supabase
      .from('dishes')
      .select()
      .eq('user_id', userId)
      .eq('date', date)
      .order('created_at', ascending: false);
  return (res as List).map((e) => DishRecord.fromMap(e as Map<String, dynamic>)).toList();
}

/// Даты в указанном месяце, на которые есть хотя бы одно блюдо (для отметок в календаре).
Future<Set<DateTime>> getDishDatesInMonth(String userId, int year, int month) async {
  if (!isSupabaseConfigured) return {};
  final start = '$year-${month.toString().padLeft(2, '0')}-01';
  final end = '$year-${month.toString().padLeft(2, '0')}-31';
  final res = await supabase
      .from('dishes')
      .select('date')
      .eq('user_id', userId)
      .gte('date', start)
      .lte('date', end);
  final dates = <DateTime>{};
  for (final e in res as List) {
    final dateStr = (e as Map<String, dynamic>)['date'] as String?;
    if (dateStr != null) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        dates.add(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])));
      }
    }
  }
  return dates;
}

Future<DishRecord?> getDishById(String dishId) async {
  if (!isSupabaseConfigured) return null;
  final res = await supabase.from('dishes').select().eq('id', dishId).maybeSingle();
  return res != null ? DishRecord.fromMap(res as Map<String, dynamic>) : null;
}

Future<DishRecord> insertDish({
  required String userId,
  required String name,
  required String date,
  String? imageUrl,
  String? description,
}) async {
  final res = await supabase.from('dishes').insert({
    'user_id': userId,
    'name': name,
    'date': date,
    'image_url': imageUrl,
    'description': description,
  }).select().single();
  return DishRecord.fromMap(res as Map<String, dynamic>);
}

Future<void> updateDish(String dishId, {String? name, String? date, String? imageUrl, String? description}) async {
  final map = <String, dynamic>{};
  if (name != null) map['name'] = name;
  if (date != null) map['date'] = date;
  if (imageUrl != null) map['image_url'] = imageUrl;
  if (description != null) map['description'] = description;
  if (map.isEmpty) return;
  await supabase.from('dishes').update(map).eq('id', dishId);
}

Future<void> deleteDish(String dishId) async {
  await supabase.from('dishes').delete().eq('id', dishId);
}
