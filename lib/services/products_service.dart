import 'package:food_ai/services/supabase_service.dart';

class ProductRecord {
  ProductRecord({
    required this.id,
    required this.name,
    required this.scope,
    this.createdBy,
    this.createdAt,
    this.calories,
    this.protein,
    this.fats,
    this.carbs,
  });

  final String id;
  final String name;
  final String scope;
  final String? createdBy;
  final DateTime? createdAt;

  /// Пищевая ценность на 100 г или 1 порцию (как задано в БД).
  final double? calories;
  final double? protein;
  final double? fats;
  final double? carbs;

  factory ProductRecord.fromMap(Map<String, dynamic> map) {
    final idRaw = map['id'];
    final scopeRaw = map['scope'];
    final createdByRaw = map['created_by'];
    final createdAtRaw = map['created_at'];
    final kcalRaw = map['calories'];
    final proteinRaw = map['protein'];
    final fatsRaw = map['fats'];
    final carbsRaw = map['carbs'];

    return ProductRecord(
      id: idRaw is String ? idRaw : idRaw?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      scope: scopeRaw?.toString() ?? 'global',
      createdBy: createdByRaw?.toString(),
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw)
          : null,
      calories: _toDoubleOrNull(kcalRaw),
      protein: _toDoubleOrNull(proteinRaw),
      fats: _toDoubleOrNull(fatsRaw),
      carbs: _toDoubleOrNull(carbsRaw),
    );
  }
}

double? _toDoubleOrNull(Object? raw) {
  if (raw is num?) return raw?.toDouble();
  final parsed = double.tryParse(raw.toString());
  return parsed;
}

Future<List<ProductRecord>> getProducts({String? userId}) async {
  if (!isSupabaseConfigured) return [];
  final query = supabase.from('products').select();
  final res = await query.order('name');
  final list = (res as List)
      .map((e) => ProductRecord.fromMap(e as Map<String, dynamic>))
      .toList();
  return list
      .where(
        (p) =>
            p.scope == 'global' || (p.scope == 'user' && p.createdBy == userId),
      )
      .toList();
}

/// Только глобальный список продуктов (для экрана «Основной список»).
Future<List<ProductRecord>> getGlobalProducts() async {
  if (!isSupabaseConfigured) return [];
  final res = await supabase
      .from('products')
      .select()
      .eq('scope', 'global')
      .order('name');
  return (res as List)
      .map((e) => ProductRecord.fromMap(e as Map<String, dynamic>))
      .toList();
}

Future<ProductRecord?> insertProduct({
  required String name,
  required String scope,
  String? createdBy,
}) async {
  final res = await supabase
      .from('products')
      .insert({
        'name': name,
        'scope': scope,
        'created_by': scope == 'user' ? createdBy : null,
      })
      .select()
      .maybeSingle();
  if (res == null) return null;
  return ProductRecord.fromMap(res);
}

Future<void> deleteProduct(String productId) async {
  await supabase.from('products').delete().eq('id', productId);
}
