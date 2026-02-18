/// Заглушка ИИ: возвращает фиксированные название и список продуктов.
/// Позже заменить на вызов реального API.
Future<AiAnalysisResult> analyzeDishImage(List<int> imageBytes) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return const AiAnalysisResult(
    dishName: 'Блюдо по фото',
    productNames: ['Картофель', 'Мясо', 'Лук', 'Морковь', 'Соль'],
  );
}

/// Анализ текстового описания (добавление без фото).
Future<AiAnalysisResult> analyzeDishDescription(String description) async {
  await Future.delayed(const Duration(milliseconds: 400));
  if (description.trim().isEmpty) {
    return const AiAnalysisResult(dishName: 'Блюдо', productNames: []);
  }
  return AiAnalysisResult(
    dishName: description.length > 30 ? '${description.substring(0, 30)}...' : description,
    productNames: ['Ингредиент 1', 'Ингредиент 2'],
  );
}

class AiAnalysisResult {
  const AiAnalysisResult({
    required this.dishName,
    required this.productNames,
  });

  final String dishName;
  final List<String> productNames;
}
