import 'package:food_ai/services/supabase_service.dart';
import 'package:food_ai/services/products_service.dart';

Future<List<ProductRecord>> getProductsForDish(String dishId) async {
  if (!isSupabaseConfigured) return [];
  final res = await supabase
      .from('dish_products')
      .select('product_id, is_user_added')
      .eq('dish_id', dishId);
  final productIds = (res as List)
      .map((e) => (e as Map<String, dynamic>)['product_id'])
      .where((id) => id != null)
      .map((id) => id.toString())
      .toList();
  if (productIds.isEmpty) return [];
  final productsRes = await supabase
      .from('products')
      .select()
      .inFilter('id', productIds);
  return (productsRes as List)
      .map((e) => ProductRecord.fromMap(e as Map<String, dynamic>))
      .toList();
}

Future<void> setDishProducts(
  String dishId,
  List<String> productIds, {
  List<String> userAddedIds = const [],
}) async {
  // Удаляем старые связи (игнорируем ошибку если записей ещё нет)
  try {
    await supabase.from('dish_products').delete().eq('dish_id', dishId);
  } catch (_) {
    // Первое сохранение — удалять нечего
  }

  if (productIds.isEmpty) return;

  // Вставляем все продукты ОДНИМ batch-запросом вместо цикла,
  // чтобы избежать «Connection reset by peer» при множественных запросах.
  final rows = productIds
      .map(
        (pid) => {
          'dish_id': dishId,
          'product_id': pid,
          'is_user_added': userAddedIds.contains(pid),
        },
      )
      .toList();

  await supabase.from('dish_products').insert(rows);
}

Future<void> addDishProduct(
  String dishId,
  String productId, {
  bool isUserAdded = false,
}) async {
  await supabase.from('dish_products').upsert({
    'dish_id': dishId,
    'product_id': productId,
    'is_user_added': isUserAdded,
  }, onConflict: 'dish_id,product_id');
}

Future<void> removeDishProduct(String dishId, String productId) async {
  await supabase
      .from('dish_products')
      .delete()
      .eq('dish_id', dishId)
      .eq('product_id', productId);
}
