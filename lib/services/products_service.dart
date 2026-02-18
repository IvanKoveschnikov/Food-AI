import 'package:food_ai/services/supabase_service.dart';

class ProductRecord {
  ProductRecord({
    required this.id,
    required this.name,
    required this.scope,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String name;
  final String scope;
  final String? createdBy;
  final DateTime? createdAt;

  factory ProductRecord.fromMap(Map<String, dynamic> map) {
    return ProductRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      scope: map['scope'] as String,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}

Future<List<ProductRecord>> getProducts({String? userId}) async {
  if (!isSupabaseConfigured) return [];
  final query = supabase.from('products').select();
  final res = await query.order('name');
  final list = (res as List).map((e) => ProductRecord.fromMap(e as Map<String, dynamic>)).toList();
  return list.where((p) => p.scope == 'global' || (p.scope == 'user' && p.createdBy == userId)).toList();
}

/// Только глобальный список продуктов (для экрана «Основной список»).
Future<List<ProductRecord>> getGlobalProducts() async {
  if (!isSupabaseConfigured) return [];
  final res = await supabase.from('products').select().eq('scope', 'global').order('name');
  return (res as List).map((e) => ProductRecord.fromMap(e as Map<String, dynamic>)).toList();
}

Future<ProductRecord?> insertProduct({
  required String name,
  required String scope,
  String? createdBy,
}) async {
  final res = await supabase.from('products').insert({
    'name': name,
    'scope': scope,
    'created_by': scope == 'user' ? createdBy : null,
  }).select().maybeSingle();
  return res != null ? ProductRecord.fromMap(res as Map<String, dynamic>) : null;
}

Future<void> deleteProduct(String productId) async {
  await supabase.from('products').delete().eq('id', productId);
}
