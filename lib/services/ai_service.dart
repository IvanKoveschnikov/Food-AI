import 'package:food_ai/core/config/env.dart';
import 'package:food_ai/services/ai_stub_service.dart' as stub;
import 'package:food_ai/services/openrouter_service.dart' as openrouter;

export 'package:food_ai/services/ai_stub_service.dart' show AiAnalysisResult;

/// Анализ фото блюда. При наличии OPENROUTER_API_KEY — OpenRouter, иначе заглушка.
Future<stub.AiAnalysisResult> analyzeDishImage(List<int> imageBytes) async {
  if (isAiConfigured) return openrouter.analyzeImage(imageBytes);
  return stub.analyzeDishImage(imageBytes);
}

/// Анализ текстового описания. При наличии OPENROUTER_API_KEY — OpenRouter, иначе заглушка.
Future<stub.AiAnalysisResult> analyzeDishDescription(String description) async {
  if (isAiConfigured) return openrouter.analyzeText(description);
  return stub.analyzeDishDescription(description);
}
