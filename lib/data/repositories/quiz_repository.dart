import 'package:flutter/foundation.dart';

import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';

class QuizRepository with ChangeNotifier {
  final List<Quiz> _quizzes = [];
  final List<QuizResult> _results = [];

  List<Quiz> get quizzes => _quizzes;
  List<QuizResult> get results => _results;

  QuizRepository() {
    _loadDemoData();
  }

  void _loadDemoData() {
    _quizzes.addAll([
      Quiz(
        id: '1',
        title: 'Математика - Основы алгебры',
        description: 'Тест по основам алгебры для 7 класса',
        subject: 'Математика',
        questions: [
          Question(
            id: '1',
            text: 'Решите уравнение: 2x + 5 = 15',
            type: QuestionType.singleChoice,
            answers: [
              Answer(id: '1', text: 'x = 5', isCorrect: true),
              Answer(id: '2', text: 'x = 10', isCorrect: false),
              Answer(id: '3', text: 'x = 7.5', isCorrect: false),
            ],
          ),
        ],
      ),
    ]);
  }

  Future<void> createQuiz(Quiz quiz) async {
    _quizzes.add(quiz);
    notifyListeners();
  }

  Future<void> updateQuiz(Quiz quiz) async {
    final index = _quizzes.indexWhere((q) => q.id == quiz.id);
    if (index != -1) {
      _quizzes[index] = quiz;
      notifyListeners();
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    _quizzes.removeWhere((q) => q.id == quizId);
    notifyListeners();
  }

  Future<void> addResult(QuizResult result) async {
    _results.add(result);
    notifyListeners();
  }

  List<QuizResult> getResultsByQuiz(String quizId) {
    return _results.where((r) => r.quizId == quizId).toList();
  }
}
