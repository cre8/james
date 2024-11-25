import 'package:james/ai_service.dart';

class DummyService implements AIService {
  @override
  Future<String> generateUpdatedText(String prompt, String originalText) async {
    return 'Response: $prompt\nOriginal Text:\n$originalText';
  }
}
