# AI-Powered Question Generation from Files - Implementation Guide

## Overview
This guide explains how to implement the feature that allows teachers to upload PDF or other files containing lecture materials, and automatically generate quiz questions using AI.

## Approach Options

### Option 1: Using OpenAI API (Recommended for University Project)
This is the easiest and most reliable approach for a university project.

#### Steps:
1. **Sign up for OpenAI API**
   - Go to https://platform.openai.com/
   - Create an account
   - Navigate to "API Keys" section
   - Create a new secret key and save it securely

2. **Install Required Dependencies in Flutter**
   ```yaml
   dependencies:
     openai: ^0.3.1
     pdf: ^3.8.1
     file_picker: ^5.2.0
   ```

3. **Implement File Processing**
   - Use `file_picker` to allow users to select PDF files
   - Use `pdf` package to extract text from PDF
   - Send extracted text to OpenAI API with a prompt like:
     ```
     "Based on the following text, generate 5 multiple-choice questions with 4 options each. Format as JSON."
     ```

4. **Flutter Implementation Example**
   ```dart
   import 'package:pdf/pdf.dart';
   import 'package:pdf/widgets.dart' as pw;
   import 'package:openai/openai.dart';
   
   class QuestionGenerator {
     static Future<List<Question>> generateQuestionsFromFile(String filePath) async {
       // Extract text from PDF
       final pdfData = await File(filePath).readAsBytes();
       final document = await PdfDocument.openData(pdfData);
       String textContent = '';
       for (int i = 0; i < document.pagesCount; i++) {
         final page = await document.getPage(i + 1);
         final text = await page.extractText();
         textContent += text;
         page.close();
       }
       document.close();
   
       // Send to OpenAI
       final response = await OpenAI.instance.createCompletion(
         model: "text-davinci-003",
         prompt: "Based on the following text, generate 5 multiple-choice questions with 4 options each. Format as JSON: $textContent",
         maxTokens: 1000,
       );
   
       // Parse and return questions
       return parseQuestionsFromResponse(response.choices.first.text);
     }
   }
   ```

### Option 2: Using Hugging Face Models
For a more independent solution without API costs.

#### Steps:
1. **Choose a Pre-trained Model**
   - Go to https://huggingface.co/
   - Search for question-generation models like:
     - `mrm8488/t5-base-finetuned-question-generation-ap`
     - `valhalla/t5-base-qg-hl`

2. **Set up a Backend Service**
   - Create a Flask/FastAPI service that runs the model
   - Deploy on Heroku, Google Cloud Run, or similar
   - Call the service from your Flutter app

3. **Implementation Example**
   ```python
   from transformers import pipeline
   import torch
   
   # Load question generation model
   qg_pipeline = pipeline("question-generation", model="mrm8488/t5-base-finetuned-question-generation-ap")
   
   def generate_questions(text):
       questions = qg_pipeline(text)
       return questions
   ```

### Option 3: Using Google's Gemini API
An alternative to OpenAI with good question generation capabilities.

#### Steps:
1. **Get Google AI API Key**
   - Go to https://aistudio.google.com/
   - Get API key from Google AI Studio

2. **Install Flutter Dependencies**
   ```yaml
   dependencies:
     google_generative_ai: ^0.4.3
   ```

3. **Implementation**
   ```dart
   import 'package:google_generative_ai/google_generative_ai.dart';
   
   class GeminiQuestionGenerator {
     static Future<List<Question>> generateQuestions(String text) async {
       final model = GenerativeModel(
         model: 'gemini-pro',
         apiKey: 'YOUR_API_KEY',
       );
       
       final prompt = '''
       Based on the following text, generate 5 multiple-choice questions with 4 options each.
       Format the response as JSON with the following structure:
       {
         "questions": [
           {
             "question": "Question text",
             "options": ["A", "B", "C", "D"],
             "correct_answer": "A"
           }
         ]
       }
       
       Text: $text
       ''';
       
       final response = await model.generateContent([Content.text(prompt)]);
       return parseQuestionsFromResponse(response.text);
     }
   }
   ```

## Recommended Implementation for University Project

For a university project, I recommend **Option 1 (OpenAI API)** because:
- Easy to implement
- Reliable results
- Well-documented
- Sufficient free tier for testing

## Complete Implementation Steps

### 1. Update pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  pdf: ^3.8.1
  file_picker: ^5.2.0
  openai: ^0.3.1
  http: ^0.13.5
```

### 2. Create File Processing Service
```dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:openai/openai.dart';

class FileQuestionGenerator {
  static Future<List<Map<String, dynamic>>> generateQuestionsFromPdf(
      String filePath) async {
    try {
      // Extract text from PDF
      final pdfData = await File(filePath).readAsBytes();
      final document = await PdfDocument.openData(pdfData);
      String textContent = '';
      
      for (int i = 0; i < document.pagesCount; i++) {
        final page = await document.getPage(i + 1);
        final text = await page.extractText();
        textContent += text;
        page.close();
      }
      document.close();
      
      // Limit text length for API
      if (textContent.length > 3000) {
        textContent = textContent.substring(0, 3000);
      }
      
      // Generate questions using OpenAI
      final response = await OpenAI.instance.createCompletion(
        model: "text-davinci-003",
        prompt: '''
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
        
        Text: $textContent
        ''',
        maxTokens: 1000,
        temperature: 0.7,
      );
      
      // Parse the response (you'll need to implement JSON parsing)
      return parseQuestionsJson(response.choices.first.text);
    } catch (e) {
      throw Exception('Error generating questions: $e');
    }
  }
  
  static List<Map<String, dynamic>> parseQuestionsJson(String response) {
    // Implement JSON parsing logic here
    // This is a simplified example
    return [];
  }
}
```

### 3. Update Your Existing Upload Button
Replace your current hardcoded question generation with the AI-powered version:

```dart
// In your quiz creation screen
Future<void> _uploadQuestionsFromFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
  );
  
  if (result != null) {
    String filePath = result.files.single.path!;
    
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      // Generate questions from file
      List<Map<String, dynamic>> questions = 
          await FileQuestionGenerator.generateQuestionsFromPdf(filePath);
      
      // Add generated questions to your quiz
      for (var questionData in questions) {
        // Add question to your quiz model
        _addQuestionToQuiz(questionData);
      }
      
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Questions generated successfully!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating questions: $e')),
      );
    }
  }
}
```

## Cost Considerations
- OpenAI API: Has a free tier for testing
- For a university project, the free tier should be sufficient
- Monitor usage to stay within limits

## Security Considerations
- Store API keys securely (use environment variables or secure storage)
- Never commit API keys to version control
- Consider using Flutter's `flutter_config` package for secure configuration

## Testing
- Test with various PDF formats and content types
- Verify that generated questions are relevant to the content
- Test error handling for invalid files or API failures

This approach will give you a working AI-powered question generation feature for your university project with minimal setup required.