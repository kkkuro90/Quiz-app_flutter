import 'dart:convert';

import '../../data/models/quiz_model.dart';

/// Сервис экспорта квизов в разные текстовые форматы.
class ExportService {
  /// Экспорт в формат GIFT (Moodle).
  static String exportToGiftFormat(Quiz quiz) {
    final buffer = StringBuffer();

    for (final question in quiz.questions) {
      buffer.writeln('::${question.id}:: ${question.text} {');

      switch (question.type) {
        case QuestionType.singleChoice:
          for (final answer in question.answers) {
            final prefix = answer.isCorrect ? '=' : '~';
            buffer.writeln('$prefix${answer.text}');
          }
          break;
        case QuestionType.multipleChoice:
          for (final answer in question.answers) {
            final prefix = answer.isCorrect ? '=' : '~';
            buffer.writeln('$prefix${answer.text}');
          }
          break;
        case QuestionType.textAnswer:
          // Для текстового ответа считаем правильными все варианты с isCorrect = true
          final correctTexts =
              question.answers.where((a) => a.isCorrect).map((a) => a.text);
          for (final text in correctTexts) {
            buffer.writeln('=${text}');
          }
          break;
      }

      buffer.writeln('}\n');
    }

    return buffer.toString();
  }

  /// Экспорт в CSV: каждая строка — вопрос с вариантами ответов.
  static String exportToCsv(Quiz quiz) {
    final buffer = StringBuffer();
    buffer.writeln('question_id,question_text,type,answer_id,answer_text,is_correct,points,topic');

    for (final question in quiz.questions) {
      for (final answer in question.answers) {
        final row = [
          _escapeCsv(question.id),
          _escapeCsv(question.text),
          question.type.index.toString(),
          _escapeCsv(answer.id),
          _escapeCsv(answer.text),
          answer.isCorrect ? '1' : '0',
          question.points.toString(),
          _escapeCsv(question.topic ?? ''),
        ];
        buffer.writeln(row.join(','));
      }
    }

    return buffer.toString();
  }

  /// Экспорт в JSON (readable).
  static String exportToJson(Quiz quiz) {
    final map = quiz.toJson();
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static String _escapeCsv(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    var escaped = value.replaceAll('"', '""');
    if (needsQuotes) {
      escaped = '"$escaped"';
    }
    return escaped;
  }
}
<<<<<<< HEAD
=======


>>>>>>> 2e096c9f1c108dfed9888cf4b77d503caf0d5935
