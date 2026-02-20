import 'package:food_ai/services/supabase_service.dart';
import 'package:food_ai/services/products_service.dart';

class DishTemplateRecord {
  DishTemplateRecord({
    required this.id,
    required this.userId,
    required this.name,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final DateTime? createdAt;

  factory DishTemplateRecord.fromMap(Map<String, dynamic> map) {
    return DishTemplateRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}

Future<List<DishTemplateRecord>> getTemplatesForUser(String userId) async {
  if (!isSupabaseConfigured) return [];
  final res = await supabase
      .from('dish_templates')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);
  return (res as List)
      .map((e) => DishTemplateRecord.fromMap(e as Map<String, dynamic>))
      .toList();
}

Future<DishTemplateRecord?> getTemplateById(String templateId) async {
  if (!isSupabaseConfigured) return null;
  final res = await supabase
      .from('dish_templates')
      .select()
      .eq('id', templateId)
      .maybeSingle();
  return res != null ? DishTemplateRecord.fromMap(res) : null;
}

Future<List<ProductRecord>> getTemplateProducts(String templateId) async {
  if (!isSupabaseConfigured) return [];
  final res = await supabase
      .from('dish_template_products')
      .select('product_id')
      .eq('template_id', templateId);
  final ids = (res as List)
      .map((e) => (e as Map<String, dynamic>)['product_id'])
      .where((id) => id != null)
      .map((id) => id.toString())
      .toList();
  if (ids.isEmpty) return [];
  final productsRes = await supabase
      .from('products')
      .select()
      .inFilter('id', ids);
  return (productsRes as List)
      .map((e) => ProductRecord.fromMap(e as Map<String, dynamic>))
      .toList();
}

Future<DishTemplateRecord?> insertTemplate({
  required String userId,
  required String name,
}) async {
  final res = await supabase
      .from('dish_templates')
      .insert({'user_id': userId, 'name': name})
      .select()
      .maybeSingle();
  return res != null ? DishTemplateRecord.fromMap(res) : null;
}

Future<void> updateTemplate(String templateId, String name) async {
  await supabase
      .from('dish_templates')
      .update({'name': name})
      .eq('id', templateId);
}

Future<void> setTemplateProducts(
  String templateId,
  List<String> productIds,
) async {
  await supabase
      .from('dish_template_products')
      .delete()
      .eq('template_id', templateId);
  for (final pid in productIds) {
    await supabase.from('dish_template_products').insert({
      'template_id': templateId,
      'product_id': pid,
    });
  }
}

Future<void> deleteTemplate(String templateId) async {
  await supabase.from('dish_templates').delete().eq('id', templateId);
}
