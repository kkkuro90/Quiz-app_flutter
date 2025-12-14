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
    // If quiz doesn't have a PIN and is being activated, generate a unique PIN
    String? finalPinCode = quiz.pinCode ?? (quiz.isActive ? await _generateUniquePinCode() : null);

    final Quiz quizWithPin = quiz.copyWith(pinCode: finalPinCode);
    final data = quizWithPin.toJson();
    await _db.collection('quizzes').add(data..remove('id'));
  }

  Future<String> _generateUniquePinCode() async {
    String pinCode = ""; // Initialize with empty string
    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 10;

    while (!isUnique && attempts < maxAttempts) {
      // Generate a random 4-digit PIN
      final random = DateTime.now().millisecondsSinceEpoch;
      pinCode = (random % 10000).toString().padLeft(4, '0');

      // Check if PIN is unique among active quizzes
      final snapshot = await _db
          .collection('quizzes')
          .where('pinCode', isEqualTo: pinCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      isUnique = snapshot.docs.isEmpty;
      attempts++;
    }

    if (!isUnique) {
      // Fallback: use hash of current time
      pinCode = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    }

    return pinCode;
  }

  Future<void> updateQuiz(Quiz quiz) async {
    if (quiz.id.isEmpty) return;

    // If quiz is being activated and doesn't have a PIN, generate one
    if (quiz.isActive && quiz.pinCode == null) {
      final uniquePin = await _generateUniquePinCode();
      final quizWithPin = quiz.copyWith(pinCode: uniquePin);
      await _db.collection('quizzes').doc(quiz.id).update(quizWithPin.toJson());
    } else {
      await _db.collection('quizzes').doc(quiz.id).update(quiz.toJson());
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    await _db.collection('quizzes').doc(quizId).delete();
  }

  Future<void> addResult(QuizResult result) async {
    _results.add(result);
    notifyListeners();

    // Сохраняем результат в Firestore
    await _db.collection('quiz_results').add(result.toJson());
  }

  List<QuizResult> getResultsByQuiz(String quizId) {
    return _results.where((r) => r.quizId == quizId).toList();
  }

  /// Получаем результаты квиза с сортировкой по дате завершения (новые первые)
  Future<List<QuizResult>> getQuizResultsWithSort(String quizId) async {
    final snapshot = await _db
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => QuizResult.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  /// Получаем результаты студента с сортировкой по дате завершения (новые первые)
  Future<List<QuizResult>> getStudentResultsWithSort(String studentId) async {
    final snapshot = await _db
        .collection('quiz_results')
        .where('studentId', isEqualTo: studentId)
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => QuizResult.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }
}
