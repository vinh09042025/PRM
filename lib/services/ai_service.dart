import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AIService {
  static const String _apiKey = 'AIzaSyD6qKXB3TcFdMhCYizIkHmqUYwb1HaGLUk';
  
  GenerativeModel? _model;

  AIService();

  /// Generates flashcards based on user preferences with model fallback logic.
  Future<List<Map<String, dynamic>>> generateFlashcards({
    required String language,
    required String difficulty,
    required String category,
    required int count,
  }) async {
    final List<String> modelsToTry = [
      'gemini-flash-latest',
      'gemini-2.0-flash',
      'gemini-pro-latest',
      'gemini-1.5-flash-latest',
    ];

    Object? lastError;

    for (String modelName in modelsToTry) {
      try {
        debugPrint('Attempting flashcard generation with model: $modelName');
        final model = GenerativeModel(model: modelName, apiKey: _apiKey);
        
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

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        
        String? jsonString = response.text;
        if (jsonString == null) continue; // Try next model if response is empty

        // Remove potential markdown backticks
        jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();

        final List<dynamic> decoded = jsonDecode(jsonString);
        debugPrint('Generation successful with model: $modelName');
        
        // Cache this model for future use if it worked
        _model = model;
        
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        lastError = e;
        debugPrint('Model $modelName failed: $e');
        // Continue to next model
      }
    }

    debugPrint('All models failed. Last error: $lastError');
    throw Exception('Failed to generate flashcards after trying multiple models. Please check your API Key permissions. Last error: $lastError');
  }
}
