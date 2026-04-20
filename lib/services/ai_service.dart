import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = 'AIzaSyC8oHoJzh99maiqELeskc2cVuGRyQTDQPM';
  
  GenerativeModel? _model;

  AIService();

  /// Initializes the model by fetching available models via REST API.
  Future<void> _initModel() async {
    if (_model != null) return;

    try {
      debugPrint('Fetching available models for API Key...');
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey');
      final response = await http.get(url);

      String foundModelName = 'gemini-1.5-flash'; // Default fallback

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> models = data['models'] ?? [];
        
        // Strategy: Look for 1.5-flash, then pro
        bool found = false;
        for (var m in models) {
          final String name = m['name'] ?? '';
          debugPrint('Discovered: $name');
          if (name.contains('gemini-1.5-flash')) {
            foundModelName = name.replaceFirst('models/', '');
            found = true;
            break;
          }
        }

        if (!found && models.isNotEmpty) {
          foundModelName = (models.first['name'] as String).replaceFirst('models/', '');
        }
      } else {
        debugPrint('Failed to list models: ${response.statusCode}. Using default.');
      }
      
      debugPrint('Decision: Using model identifier: $foundModelName');
      _model = GenerativeModel(model: foundModelName, apiKey: _apiKey);
    } catch (e) {
      debugPrint('Initialization error: $e. Falling back to static identifier.');
      _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    }
  }

  /// Generates flashcards based on user preferences.
  Future<List<Map<String, dynamic>>> generateFlashcards({
    required String language,
    required String difficulty,
    required String category,
    required int count,
  }) async {
    await _initModel();

    final prompt = '''
    Generate a list of $count flashcards for learning $language.
    Difficulty level: $difficulty.
    Topic/Category: $category.
    
    The response must be a valid JSON array of objects. 
    Each object must have exactly these keys:
    - "front": The word or phrase in $language.
    - "back": The meaning in Vietnamese.
    - "example": A short example sentence in $language using the word.
    
    Ensure the translations are accurate and common.
    Return ONLY pure JSON, no markdown formatting, no backticks.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      String? jsonString = response.text;
      if (jsonString == null) throw Exception('AI returned empty response');

      // Remove potential markdown backticks if AI ignores instruction
      jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error generating flashcards: $e');
      rethrow;
    }
  }
}
