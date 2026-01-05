import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  static const String baseUrl = 'https://api.openai.com/v1';
  static String? _apiKey;

  // Initialize the API key
  static void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  // Generate questions from text content
  static Future<List<Map<String, dynamic>>?> generateQuestionsFromText(String text) async {
    if (_apiKey == null) {
      throw Exception('OpenAI API key not initialized. Call OpenAIService.initialize() first.');
    }

    try {
      // Limit text length to stay within token limits and costs
      String processedText = text.length > 3000 ? text.substring(0, 3000) : text;

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey!',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that generates quiz questions based on provided text. Respond with a JSON object containing an array of questions.'
            },
            {
              'role': 'user',
              'content': '''
                Based on the following text, generate 5 multiple-choice questions with 4 options each.
                Format as JSON with this structure:
                {
                  "questions": [
                    {
                      "question": "Question text",
                      "options": ["Option A", "Option B", "Option C", "Option D"],
                      "correct_answer": "Option A"
                    }
                  ]
                }
                
                Text: $processedText
              '''
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questionsText = data['choices'][0]['message']['content'].trim();
        
        // Extract JSON from the response (in case it includes extra text)
        int startIndex = questionsText.indexOf('{');
        int endIndex = questionsText.lastIndexOf('}') + 1;
        
        if (startIndex != -1 && endIndex != 0) {
          String jsonStr = questionsText.substring(startIndex, endIndex);
          final jsonData = jsonDecode(jsonStr);
          
          if (jsonData.containsKey('questions')) {
            return List<Map<String, dynamic>>.from(jsonData['questions']);
          }
        }
        
        // If JSON parsing fails, try to parse as raw JSON
        try {
          final jsonData = jsonDecode(questionsText);
          if (jsonData.containsKey('questions')) {
            return List<Map<String, dynamic>>.from(jsonData['questions']);
          }
        } catch (e) {
          print('Error parsing JSON: $e');
          print('Response text: $questionsText');
        }
      } else {
        print('OpenAI API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate questions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling OpenAI API: $e');
      throw Exception('Error generating questions: $e');
    }

    return null;
  }
}