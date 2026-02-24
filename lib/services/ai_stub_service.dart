/// Заглушка ИИ: возвращает фиксированные название и список продуктов.
/// Позже заменить на вызов реального API.
Future<AiAnalysisResult> analyzeDishImage(List<int> imageBytes) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return const AiAnalysisResult(
    dishName: 'блюдо по фото',
    description: 'пример описания блюда по фото',
    aiAdvice: 'Это сбалансированное блюдо, богатое белком. Подходит для обеда.',
    confidence: 85,
    productNames: ['картофель', 'мясо', 'лук', 'морковь', 'соль'],
  );
}

/// Анализ текстового описания (добавление без фото).
Future<AiAnalysisResult> analyzeDishDescription(String description) async {
  await Future.delayed(const Duration(milliseconds: 400));
  if (description.trim().isEmpty) {
    return const AiAnalysisResult(
      dishName: 'Блюдо',
      description: '',
      aiAdvice: '',
      confidence: 0,
      productNames: [],
    );
  }
  return AiAnalysisResult(
    dishName: description.length > 30
        ? '${description.substring(0, 30)}...'
        : description,
    description: description,
    aiAdvice: 'Рекомендуется употреблять 1-2 раза в день.',
    confidence: 70,
    productNames: ['ингредиент 1', 'ингредиент 2'],
  );
}

class AiAnalysisResult {
  const AiAnalysisResult({
    required this.dishName,
    required this.description,
    required this.aiAdvice,
    required this.confidence,
    required this.productNames,
  });

  final String dishName;
  final String description;
  final String aiAdvice;
  final int confidence;
  final List<String> productNames;
}
