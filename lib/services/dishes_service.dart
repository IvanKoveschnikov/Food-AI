import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
bool get isSupabaseConfigured =>
    true; // Assuming configuration is done elsewhere or this is a placeholder check

class DishRecord {
  final String id;
  final String userId;
  final String name;
  final String date;
  final String? imageUrl;
  final String? description;
  final String? aiAdvice;
  final int confidence;
  final int weightGrams;
  final DateTime createdAt;

  DishRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    this.imageUrl,
    this.description,
    this.aiAdvice,
    this.confidence = 0,
    this.weightGrams = 100,
    required this.createdAt,
  });

  factory DishRecord.fromMap(Map<String, dynamic> map) {
    return DishRecord(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      name: map['name'].toString(),
      date: map['date'].toString(),
      imageUrl: map['image_url']?.toString(),
      description: map['description']?.toString(),
      aiAdvice: map['ai_advice']?.toString(),
      confidence: (map['confidence'] as num?)?.toInt() ?? 0,
      weightGrams: (map['weight_grams'] as num?)?.toInt() ?? 100,
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }
}

Future<DishRecord> insertDish({
  required String userId,
  required String name,
  required String date,
  String? imageUrl,
  String? description,
  String? aiAdvice,
  int confidence = 0,
  int weightGrams = 100,
}) async {
  final res = await supabase
      .from('saved_dishes')
      .insert({
        'user_id': userId,
        'name': name,
        'date': date,
        'image_url': imageUrl,
        'description': description,
        'ai_advice': aiAdvice,
        'confidence': confidence,
        'weight_grams': weightGrams,
      })
      .select()
      .single();
  return DishRecord.fromMap(res as Map<String, dynamic>);
}

Future<void> updateDish(
  String id, {
  String? name,
  String? description,
  String? aiAdvice,
  int? confidence,
  int? weightGrams,
}) async {
  final updates = <String, dynamic>{};
  if (name != null) updates['name'] = name;
  if (description != null) updates['description'] = description;
  if (aiAdvice != null) updates['ai_advice'] = aiAdvice;
  if (confidence != null) updates['confidence'] = confidence;
  if (weightGrams != null) updates['weight_grams'] = weightGrams;
  if (updates.isEmpty) return;
  await supabase.from('saved_dishes').update(updates).eq('id', id);
}

Future<List<DishRecord>> getDishesForDate(String userId, String date) async {
  if (!isSupabaseConfigured) return [];
  final res = await supabase
      .from('saved_dishes')
      .select()
      .eq('user_id', userId)
      .eq('date', date)
      .order('created_at', ascending: false);
  return (res as List)
      .map((e) => DishRecord.fromMap(e as Map<String, dynamic>))
      .toList();
}

Stream<List<DishRecord>> streamDishesForDate(String userId, String date) {
  if (!isSupabaseConfigured) return Stream.value([]);
  // В данной версии SupabaseStreamBuilder может не поддерживать .eq() напрямую или требует другого синтаксиса.
  // Используем фильтрацию на клиенте. RLS должен ограничивать доступ к чужим данным.
  return supabase
      .from('saved_dishes')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) {
        final dishes = data.map((e) => DishRecord.fromMap(e)).toList();
        return dishes
            .where((d) => d.userId == userId && d.date == date)
            .toList();
      });
}

Future<DishRecord?> getDishById(String id) async {
  if (!isSupabaseConfigured) return null;
  try {
    final res = await supabase
        .from('saved_dishes')
        .select()
        .eq('id', id)
        .single();
    return DishRecord.fromMap(res as Map<String, dynamic>);
  } catch (e) {
    // ignore: avoid_print
    print('getDishById error: $e');
    return null;
  }
}

Future<void> deleteDish(String id) async {
  if (!isSupabaseConfigured) return;
  await supabase.from('saved_dishes').delete().eq('id', id);
}

/// Даты в указанном месяце, на которые есть хотя бы одно блюдо (для отметок в календаре).
Future<Set<DateTime>> getDishDatesInMonth(
  String userId,
  int year,
  int month,
) async {
  if (!isSupabaseConfigured) return {};
  final start = '$year-${month.toString().padLeft(2, '0')}-01';
  final end = '$year-${month.toString().padLeft(2, '0')}-31';
  final res = await supabase
      .from('saved_dishes')
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
        dates.add(
          DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ),
        );
      }
    }
  }
  return dates;
}
