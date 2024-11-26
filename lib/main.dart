import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:james/ai/dummy.dart';
import 'package:james/ai/openapi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';
import 'text_selection.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Updater',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TextUpdaterScreen(),
    );
  }
}

class TextUpdaterScreen extends StatefulWidget {
  const TextUpdaterScreen({super.key});

  @override
  TextUpdaterScreenState createState() => TextUpdaterScreenState();
}

class TextUpdaterScreenState extends State<TextUpdaterScreen> {
  /// The API key for the OpenAI service
  String _apiKey = '';

  /// The project for the OpenAI service
  String _project = '';

  /// The selected prompt
  String selectedPrompt = '';

  /// Whether the app is loading
  bool _isLoading = false;

  /// The AI service
  late AIService _aiService;

  /// The text controllers for the original and updated text
  late TextEditingController _originalTextController;

  /// The text controllers for the original and updated text
  late TextEditingController _updatedTextController;

  /// The list of prompts
  final List<String> prompts = [
    "Please update the text with better grammar and formatting.",
    "Summarize the following text.",
    "Translate the following text to Spanish.",
    "Rewrite the text to make it more formal.",
    "Simplify the text for a younger audience."
  ];

  /// The list of AI services
  final List<String> aiServices = [
    "Dummy",
    "OpenAI",
  ];

  String selectedAIService = "Dummy";

  @override
  void initState() {
    super.initState();
    _registerHotKey();
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    _project = dotenv.env['OPENAI_PROJECT'] ?? '';

    _originalTextController = TextEditingController();
    _updatedTextController = TextEditingController();

    _loadSelectedAIService();
    _loadSelectedPrompt();
  }

  /// Register the hot key to paste the clipboard text
  Future<void> _registerHotKey() async {
    await hotKeyManager.register(
      HotKey(
          key: PhysicalKeyboardKey.keyN, modifiers: [HotKeyModifier.control]),
      keyDownHandler: (hotKey) async {
        final selectedText = await TextSelection2.getSelectedText();
        print('Selected Text: $selectedText');
        //String copiedText = await FlutterClipboard.paste();
        setState(() {
          _originalTextController.text = selectedText ?? '';
        });

        await _transformText();
      },
    );
  }

  /// Transform the text using the selected AI service
  Future<void> _transformText() async {
    setState(() {
      _isLoading = true;
    });

    String updatedText = await _aiService.generateUpdatedText(
        selectedPrompt, _originalTextController.text);

    setState(() {
      _updatedTextController.text = updatedText;
      _isLoading = false;
    });
  }

  /// Save and load the selected AI service and prompt
  Future<void> _saveSelectedAIService(String aiService) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedAIService', aiService);
  }

  /// Load the selected AI service
  Future<void> _loadSelectedAIService() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedAIService = prefs.getString('selectedAIService') ?? aiServices[0];
      _initializeAIService();
    });
  }

  /// Save the selected prompt
  Future<void> _saveSelectedPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedPrompt', prompt);
  }

  /// Load the selected prompt
  Future<void> _loadSelectedPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedPrompt = prefs.getString('selectedPrompt') ?? prompts[0];
    });
  }

  /// Initialize the selected AI service
  void _initializeAIService() {
    if (selectedAIService == "Dummy") {
      _aiService = DummyService();
    } else if (selectedAIService == "OpenAI") {
      _aiService = OpenAIService(_apiKey, _project);
    }
    // Add other AI service initializations here
  }

  /// Dispose the text controllers and unregister hot keys
  @override
  void dispose() {
    _originalTextController.dispose();
    _updatedTextController.dispose();
    hotKeyManager.unregisterAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Updater'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedPrompt.isNotEmpty ? selectedPrompt : null,
                  hint: const Text('Select a prompt'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPrompt = newValue!;
                      _saveSelectedPrompt(selectedPrompt);
                    });
                  },
                  items: prompts.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value:
                      selectedAIService.isNotEmpty ? selectedAIService : null,
                  hint: const Text('Select an AI service'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedAIService = newValue!;
                      _initializeAIService();
                      _saveSelectedAIService(selectedAIService);
                    });
                  },
                  items:
                      aiServices.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _originalTextController,
                            decoration: const InputDecoration(
                                labelText: 'Original Text'),
                            maxLines: 8,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _transformText,
                            child: const Text('Transform'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _updatedTextController,
                            decoration: const InputDecoration(
                                labelText: 'Updated Text'),
                            maxLines: 8,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
