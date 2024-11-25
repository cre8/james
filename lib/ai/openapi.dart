import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_service.dart';

class OpenAIService implements AIService {
  final String apiKey;
  final String project;

  OpenAIService(this.apiKey, this.project);

  @override
  Future<String> generateUpdatedText(String prompt, String originalText) async {
    const url = 'https://api.openai.com/v1/chat/completions';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey'
      },
      body: json.encode({
        'model': 'gpt-4o-mini', // Use the model you prefer
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                "type": "text",
                "text": '$prompt\nOriginal Text:\n$originalText',
              }
            ]
          }
        ],
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final decodedBytes = utf8.decode(response.bodyBytes);
      final data = json.decode(decodedBytes);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to generate updated text: ${response.body}');
    }
  }
}
