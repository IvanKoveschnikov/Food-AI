import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:food_ai/core/config/env.dart';
import 'package:food_ai/services/ai_stub_service.dart' as stub;

const _baseUrl = 'https://openrouter.ai/api/v1';
const _model = 'openai/gpt-4o-mini';

const _visionPrompt = r'''
По фото блюда определи название блюда и список продуктов (ингредиентов).
Ответь строго в формате JSON, без markdown и без пояснений:
{"dishName": "название блюда", "productNames": ["продукт1", "продукт2", ...]}
Только валидный JSON.
''';

const _textPrompt = r'''
По описанию блюда определи возможное название и список продуктов (ингредиентов).
Ответь строго в формате JSON, без markdown и без пояснений:
{"dishName": "название", "productNames": ["продукт1", "продукт2", ...]}
Только валидный JSON.
''';

Future<stub.AiAnalysisResult> analyzeImage(List<int> imageBytes) async {
  if (openRouterApiKey.isEmpty) return stub.analyzeDishImage(imageBytes);
  final base64 = base64Encode(imageBytes);
  final body = {
    'model': _model,
    'messages': [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': _visionPrompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64'},
          },
        ],
      },
    ],
  };
  final res = await http.post(
    Uri.parse('$_baseUrl/chat/completions'),
    headers: {
      'Authorization': 'Bearer $openRouterApiKey',
      'Content-Type': 'application/json',
      'Referer': 'https://food-ai.app',
      'X-Title': 'Food AI App',
    },
    body: jsonEncode(body),
  );
  if (res.statusCode != 200) {
    print('OpenRouter error: ${res.statusCode} - ${res.body}');
    // Логирование деталей ошибки для диагностики
    if (res.statusCode == 400) {
      throw Exception(
        'OpenRouter 400 Bad Request: Проверьте формат запроса и параметры. Ответ: ${res.body}',
      );
    } else if (res.statusCode == 401) {
      throw Exception(
        'OpenRouter 401 Unauthorized: Проверьте API ключ. Ответ: ${res.body}',
      );
    } else if (res.statusCode == 405) {
      throw Exception(
        'OpenRouter 405 Method Not Allowed: Проверьте HTTP метод запроса. Ответ: ${res.body}',
      );
    } else if (res.statusCode == 429) {
      throw Exception(
        'OpenRouter 429 Too Many Requests: Превышены лимиты запросов. Ответ: ${res.body}',
      );
    } else {
      throw Exception('OpenRouter Error (${res.statusCode}): ${res.body}');
    }
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final content = (data['choices'] as List).isNotEmpty
      ? (data['choices'] as List).first['message']['content'] as String?
      : null;
  if (content == null || content.isEmpty) throw Exception('Пустой ответ ИИ');
  return _parseJsonResponse(content);
}

Future<stub.AiAnalysisResult> analyzeText(String description) async {
  if (openRouterApiKey.isEmpty) return stub.analyzeDishDescription(description);
  if (description.trim().isEmpty) {
    return const stub.AiAnalysisResult(dishName: 'Блюдо', productNames: []);
  }
  final body = {
    'model': _model,
    'messages': [
      {'role': 'user', 'content': '$_textPrompt\n\nОписание: $description'},
    ],
  };
  final res = await http.post(
    Uri.parse('$_baseUrl/chat/completions'),
    headers: {
      'Authorization': 'Bearer $openRouterApiKey',
      'Content-Type': 'application/json',
      'Referer': 'https://food-ai.app',
      'X-Title': 'Food AI App',
    },
    body: jsonEncode(body),
  );
  if (res.statusCode != 200) {
    print('OpenRouter error: ${res.statusCode} - ${res.body}');
    // Логирование деталей ошибки для диагностики
    if (res.statusCode == 400) {
      throw Exception(
        'OpenRouter 400 Bad Request: Проверьте формат запроса и параметры. Ответ: ${res.body}',
      );
    } else if (res.statusCode == 401) {
      throw Exception(
        'OpenRouter 401 Unauthorized: Проверьте API ключ. Ответ: ${res.body}',
      );
    } else if (res.statusCode == 405) {
      throw Exception(
        'OpenRouter 405 Method Not Allowed: Проверьте HTTP метод запроса. Ответ: ${res.body}',
      );
    } else if (res.statusCode == 429) {
      throw Exception(
        'OpenRouter 429 Too Many Requests: Превышены лимиты запросов. Ответ: ${res.body}',
      );
    } else {
      throw Exception('OpenRouter Error (${res.statusCode}): ${res.body}');
    }
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final content = (data['choices'] as List).isNotEmpty
      ? (data['choices'] as List).first['message']['content'] as String?
      : null;
  if (content == null || content.isEmpty) throw Exception('Пустой ответ ИИ');
  return _parseJsonResponse(content);
}

stub.AiAnalysisResult _parseJsonResponse(String content) {
  String raw = content.trim();
  if (raw.startsWith('```')) {
    raw = raw
        .replaceFirst(RegExp(r'^```\w*\n?'), '')
        .replaceAll(RegExp(r'\n?```$'), '');
  }
  raw = raw.trim();
  final map = jsonDecode(raw) as Map<String, dynamic>;
  final dishName = map['dishName'] as String? ?? 'Блюдо';
  final list = map['productNames'];
  final productNames = list is List
      ? list.map((e) => e.toString()).toList()
      : <String>[];
  return stub.AiAnalysisResult(dishName: dishName, productNames: productNames);
}
