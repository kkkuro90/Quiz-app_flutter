import 'dart:io';

class FileProcessingService {
  // Extract text from text files
  static Future<String> extractTextFromTxt(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      return content;
    } catch (e) {
      print('Error reading text file: $e');
      throw Exception('Could not read text file: $e');
    }
  }

  // Determine file type and extract text accordingly
  static Future<String> extractTextFromFile(String filePath) async {
    final fileExtension = filePath.split('.').last.toLowerCase();

    switch (fileExtension) {
      case 'pdf':
        // For PDF files, we'll throw an exception since text extraction is complex
        // and requires native platform code that may not be available in all environments
        throw Exception('PDF support requires additional setup. Please use TXT files for now.');
      case 'txt':
        return await extractTextFromTxt(filePath);
      default:
        throw Exception('Unsupported file type: $fileExtension. Only TXT files are supported.');
    }
  }
}