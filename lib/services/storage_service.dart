import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_ai/services/supabase_service.dart';

const String dishImagesBucket = 'dish-images';

Future<String?> uploadDishImage({
  required String userId,
  required String dishId,
  required File file,
}) async {
  if (!isSupabaseConfigured) return null;
  final path = '$userId/${dishId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await supabase.storage.from(dishImagesBucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
  return path;
}

Future<String?> uploadDishImageBytes({
  required String userId,
  required String dishId,
  required Uint8List bytes,
}) async {
  if (!isSupabaseConfigured) return null;
  final path = '$userId/${dishId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await supabase.storage.from(dishImagesBucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
  return path;
}

Future<String?> getDishImageSignedUrl(String path, {int expiresIn = 3600}) async {
  if (!isSupabaseConfigured) return null;
  try {
    final res = await supabase.storage.from(dishImagesBucket).createSignedUrl(path, expiresIn);
    return res;
  } catch (_) {
    return null;
  }
}
