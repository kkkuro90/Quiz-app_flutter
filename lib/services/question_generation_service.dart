import 'package:file_picker/file_picker.dart';
import 'openai_service.dart';
import 'file_processing_service.dart';

class QuestionGenerationService {
  // Main function to generate questions from file
  static Future<List<Map<String, dynamic>>?> generateQuestionsFromFile() async {
    try {
      // Pick file from device
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        String filePath = result.files.single.path!;
        
        // Extract text from the selected file
        String fileContent = await FileProcessingService.extractTextFromFile(filePath);
        
        // Generate questions using OpenAI
        List<Map<String, dynamic>>? questions = 
            await OpenAIService.generateQuestionsFromText(fileContent);
        
        return questions;
      } else {
        // User canceled the file picker
        return null;
      }
    } catch (e) {
      print('Error in question generation process: $e');
      throw Exception('Error generating questions from file: $e');
    }
  }
}