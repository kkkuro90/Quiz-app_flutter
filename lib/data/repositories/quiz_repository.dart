import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';

/// QuizRepository: базовый Quiz API (CRUD) на Firestore
class QuizRepository with ChangeNotifier {
  final FirebaseFirestore _db;

  final List<Quiz> _quizzes = [];
  final List<QuizResult> _results = [];

  List<Quiz> get quizzes => List.unmodifiable(_quizzes);
  List<QuizResult> get results => List.unmodifiable(_results);

  QuizRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _listenQuizzes();
  }

  void _listenQuizzes() {
    _db.collection('quizzes').snapshots().listen((snapshot) {
      _quizzes
        ..clear()
        ..addAll(
          snapshot.docs.map(
            (doc) => Quiz.fromJson({
              'id': doc.id,
              ...doc.data(),
            }),
          ),
        );
      notifyListeners();
    });
  }

  Future<void> createQuiz(Quiz quiz) async {
    final data = quiz.toJson();
    await _db.collection('quizzes').add(data..remove('id'));
  }

  Future<void> updateQuiz(Quiz quiz) async {
    if (quiz.id.isEmpty) return;
    await _db.collection('quizzes').doc(quiz.id).update(quiz.toJson());
  }

  Future<void> deleteQuiz(String quizId) async {
    await _db.collection('quizzes').doc(quizId).delete();
  }

  Future<void> addResult(QuizResult result) async {
    _results.add(result);
    notifyListeners();
    // при желании здесь можно добавить сохранение результатов в БД
  }

  List<QuizResult> getResultsByQuiz(String quizId) {
    return _results.where((r) => r.quizId == quizId).toList();
  }
}
