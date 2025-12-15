import '../../data/models/quiz_model.dart';

class ExportService {
  /// Экспорт квиза в формате GIFT для Moodle
  static String exportToGiftFormat(Quiz quiz) {
    StringBuffer gift = StringBuffer();
    
    gift.writeln("// Quiz: ${quiz.title}");
    gift.writeln("// Description: ${quiz.description}");
    gift.writeln("");
    
    for (int i = 0; i < quiz.questions.length; i++) {
      final question = quiz.questions[i];
      gift.writeln("${question.text} {");
      
      if (question.type == QuestionType.singleChoice) {
        for (final answer in question.answers) {
          if (answer.isCorrect) {
            gift.writeln("    =${answer.text}");
          } else {
            gift.writeln("    ~${answer.text}");
          }
        }
      } else if (question.type == QuestionType.multipleChoice) {
        for (final answer in question.answers) {
          if (answer.isCorrect) {
            gift.writeln("    =%100%${answer.text}");
          } else {
            gift.writeln("    =%0%${answer.text}");
          }
        }
      } else if (question.type == QuestionType.textAnswer) {
        // For text answers, we provide a sample answer
        final correctAnswer = question.answers.firstWhere(
          (a) => a.isCorrect, 
          orElse: () => question.answers.first
        );
        gift.writeln("    =${correctAnswer.text}");
      }
      
      gift.writeln("}");
      gift.writeln("");
    }
    
    return gift.toString();
  }

  /// Экспорт квиза в формате JSON
  static String exportToJson(Quiz quiz) {
    return quiz.toJson().toString();
  }

  /// Экспорт квиза в формате CSV
  static String exportToCsv(Quiz quiz) {
    StringBuffer csv = StringBuffer();
    
    csv.writeln("Question,Type,Answer,Is Correct");
    
    for (final question in quiz.questions) {
      for (final answer in question.answers) {
        csv.writeln('"${question.text.replaceAll('"', '""')}",'
                   '"${_getQuestionTypeString(question.type)}",'
                   '"${answer.text.replaceAll('"', '""')}",'
                   '"${answer.isCorrect}"');
      }
    }
    
    return csv.toString();
  }

  /// Экспорт статистики квиза в формате CSV
  static String exportQuizStatsToCsv(Quiz quiz, List<Map<String, dynamic>> results) {
    StringBuffer csv = StringBuffer();
    
    csv.writeln("Student Name,Percentage,Grade,Total Points,Max Points,Completed At");
    
    for (final result in results) {
      csv.writeln('"${result['studentName'].toString().replaceAll('"', '""')}",'
                 '"${result['percentage']}",'
                 '"${result['grade']}",'
                 '"${result['totalPoints']}",'
                 '"${result['maxPoints']}",'
                 '"${result['completedAt']}"');
    }
    
    return csv.toString();
  }

  static String _getQuestionTypeString(QuestionType type) {
    switch (type) {
      case QuestionType.singleChoice:
        return "Single Choice";
      case QuestionType.multipleChoice:
        return "Multiple Choice";
      case QuestionType.textAnswer:
        return "Text Answer";
    }
  }
}