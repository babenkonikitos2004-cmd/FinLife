import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static const String _apiUrl = 'https://api.deepseek.com/chat/completions';

  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('deepseek_api_key') ?? '';
  }

  static Future<List<Map<String, String>>> getFinancialAdvice({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categorySpending,
    required double savingsRate,
    required List<String> goals,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('API ключ не указан. Добавьте ключ в Профиль → ИИ-советник');
    }

    final categoryText = categorySpending.entries
        .map((e) => '${_translateCategory(e.key)}: ${e.value.abs().toStringAsFixed(0)}₽')
        .join(', ');

    final prompt = '''
Проанализируй финансы пользователя и дай 3 конкретных совета на русском языке.

Данные за текущий месяц:
- Доходы: ${totalIncome.toStringAsFixed(0)} ₽
- Расходы: ${totalExpenses.abs().toStringAsFixed(0)} ₽  
- Сбережения: ${savingsRate.toStringAsFixed(1)}%
- По категориям: $categoryText
- Цели: ${goals.isEmpty ? 'не указаны' : goals.join(', ')}

Правила:
1. Каждый совет максимум 2 предложения
2. Используй конкретные цифры из данных
3. Будь практичным и конкретным

Ответ ТОЛЬКО в JSON (без markdown, без текста вне JSON):
{"advice": [{"title": "заголовок", "text": "текст совета", "type": "warning"}, {"title": "...", "text": "...", "type": "tip"}, {"title": "...", "text": "...", "type": "positive"}]}
Типы: warning (красный), tip (оранжевый), positive (зелёный)
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'max_tokens': 600,
          'temperature': 0.7,
          'messages': [
            {
              'role': 'system',
              'content': 'Ты финансовый советник. Отвечай только на русском языке. Отвечай только валидным JSON без markdown.'
            },
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Clean JSON from possible markdown
        final cleanJson = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final parsed = jsonDecode(cleanJson);
        final adviceList = parsed['advice'] as List;
        return adviceList.map((a) => {
          'title': a['title'].toString(),
          'text': a['text'].toString(),
          'type': a['type'].toString(),
        }).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Неверный API ключ. Проверьте ключ в настройках профиля.');
      } else {
        throw Exception('Ошибка API: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Превышено время ожидания. Проверьте интернет соединение.');
      }
      rethrow;
    }
  }

  static String _translateCategory(String categoryId) {
    const map = {
      'food': 'Еда',
      'transport': 'Транспорт',
      'health': 'Здоровье',
      'entertainment': 'Развлечения',
      'clothing': 'Одежда',
      'salary': 'Зарплата',
      'investments': 'Инвестиции',
      'gifts': 'Подарки',
      'cafe': 'Кафе',
      'other': 'Другое',
    };
    return map[categoryId] ?? categoryId;
  }
}