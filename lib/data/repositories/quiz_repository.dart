import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import '../../core/services/quiz_statistics_service.dart';

class QuizRepository with ChangeNotifier {
  final FirebaseFirestore _db;
  final QuizStatisticsService _statisticsService;

  final List<Quiz> _quizzes = [];
  final List<QuizResult> _results = [];

  List<Quiz> get quizzes => List.unmodifiable(_quizzes);
  List<QuizResult> get results => List.unmodifiable(_results);

  QuizRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance,
        _statisticsService = QuizStatisticsService() {
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
    _db.collection('quiz_results').snapshots().listen((snapshot) {
      _results
        ..clear()
        ..addAll(
          snapshot.docs.map(
            (doc) => QuizResult.fromJson(doc.data(), doc.id),
          ),
        );
      notifyListeners();
    });
  }

  Future<void> createQuiz(Quiz quiz) async {
    Quiz quizWithPin = quiz;
    // Only generate automatic PIN if no manual PIN was provided AND quiz is active
    if (quiz.pinCode == null && quiz.isActive) {
      final pinResult = await _generatePinCodeWithExpiration();
      quizWithPin = quiz.copyWith(
        pinCode: pinResult['pinCode'],
        pinExpiresAt: pinResult['expiresAt'] != null ? DateTime.parse(pinResult['expiresAt']!) : null,
      );
    } else if (quiz.pinCode != null && quiz.isActive) {
      // If manual PIN exists and quiz is active, set expiration time
      quizWithPin = quiz.copyWith(
        pinExpiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
    }

    final data = quizWithPin.toJson();
    await _db.collection('quizzes').add(data..remove('id'));
  }

  Future<String> _generateUniquePinCode() async {
    String pinCode = "";
    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 10;
    while (!isUnique && attempts < maxAttempts) {
      final random = DateTime.now().millisecondsSinceEpoch;
      pinCode = (random % 10000).toString().padLeft(4, '0');
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
      pinCode = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    }

    return pinCode;
  }
  Future<Map<String, String>> _generatePinCodeWithExpiration() async {
    final pinCode = await _generateUniquePinCode();
    final expiresAt = DateTime.now().add(const Duration(hours: 24));
    return {
      'pinCode': pinCode,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
  Future<bool> isValidPinCode(String pinCode) async {
    // Сначала проверяем активные квизы с установленным isActive
    final snapshot = await _db
        .collection('quizzes')
        .where('pinCode', isEqualTo: pinCode)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final quizData = snapshot.docs.first.data();
      final expiresAtStr = quizData['pinExpiresAt'] as String?;

      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        return DateTime.now().isBefore(expiresAt);
      }
      return true;
    }

    // Если не найден активный квиз, проверяем квизы по времени
    final allQuizzesSnapshot = await _db
        .collection('quizzes')
        .where('pinCode', isEqualTo: pinCode)
        .get();

    for (final doc in allQuizzesSnapshot.docs) {
      final quizData = doc.data();
      final quiz = Quiz.fromJson(quizData, doc.id);

      // Проверяем, активен ли квиз по времени
      if (quiz.scheduledAt != null) {
        final start = quiz.scheduledAt!;
        final end = start.add(Duration(minutes: quiz.duration));
        final now = DateTime.now();
        final isTimeActive = now.isAfter(start.subtract(const Duration(seconds: 1))) &&
            now.isBefore(end);

        if (isTimeActive) {
          final expiresAtStr = quizData['pinExpiresAt'] as String?;
          if (expiresAtStr != null) {
            final expiresAt = DateTime.parse(expiresAtStr);
            if (DateTime.now().isAfter(expiresAt)) {
              continue; // Пропускаем просроченные PIN
            }
          }
          return true;
        }
      }
    }

    return false;
  }

  Future<Quiz?> getQuizByPinCode(String pinCode) async {
    try {
      // Сначала ищем активные квизы с установленным isActive
      final snapshot = await _db
          .collection('quizzes')
          .where('pinCode', isEqualTo: pinCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final quiz = Quiz.fromJson(doc.data(), doc.id);

        if (quiz.pinExpiresAt != null && DateTime.now().isAfter(quiz.pinExpiresAt!)) {
          return null;
        }

        return quiz;
      }

      // Если не найден активный квиз, проверяем квизы по времени
      final allQuizzesSnapshot = await _db
          .collection('quizzes')
          .where('pinCode', isEqualTo: pinCode)
          .get();

      for (final doc in allQuizzesSnapshot.docs) {
        final quiz = Quiz.fromJson(doc.data(), doc.id);

        // Проверяем, активен ли квиз по времени
        bool isTimeActive = false;
        if (quiz.scheduledAt != null) {
          final start = quiz.scheduledAt!;
          final end = start.add(Duration(minutes: quiz.duration));
          final now = DateTime.now();
          isTimeActive = now.isAfter(start.subtract(const Duration(seconds: 1))) &&
              now.isBefore(end);
        }

        if (isTimeActive) {
          if (quiz.pinExpiresAt != null && DateTime.now().isAfter(quiz.pinExpiresAt!)) {
            continue; // Пропускаем просроченные PIN
          }
          return quiz;
        }
      }
    } catch (e) {
      print('Error getting quiz by PIN: $e');
    }

    return null;
  }

  Future<void> updateQuizStatus(String quizId, bool isActive) async {
    final quiz = _quizzes.firstWhere((q) => q.id == quizId, orElse: () => Quiz(
      id: quizId,
      title: '',
      description: '',
      subject: '',
      questions: [],
    ));

    // Create update data that preserves existing PIN code and expiration
    Map<String, dynamic> updateData = {
      'isQuizActive': isActive,
      'isActive': isActive,
    };

    // If activating and there's a manual PIN code, ensure expiration is set
    if (isActive && quiz.pinCode != null && quiz.pinCode!.isNotEmpty) {
      updateData['pinExpiresAt'] = DateTime.now().add(const Duration(hours: 24)).toIso8601String();
    }

    await _db.collection('quizzes').doc(quizId).update(updateData);
    if (quiz.id.isNotEmpty) {
      final updatedQuiz = quiz.copyWith(
        isQuizActive: isActive,
        isActive: isActive,
        pinExpiresAt: isActive && quiz.pinCode != null && quiz.pinCode!.isNotEmpty
            ? DateTime.now().add(const Duration(hours: 24))
            : quiz.pinExpiresAt,
      );
      final index = _quizzes.indexWhere((q) => q.id == quizId);
      if (index != -1) {
        _quizzes[index] = updatedQuiz;
        notifyListeners();
      }
    }
  }

  Future<bool> isQuizActiveAtTime(String quizId, {DateTime? checkTime}) async {
    final doc = await _db.collection('quizzes').doc(quizId).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final scheduledAt = data['scheduledAt'] != null
        ? DateTime.parse(data['scheduledAt'])
        : null;
    final duration = data['duration'] as int? ?? 30;
    final startTime = data['startTime'] != null
        ? DateTime.parse(data['startTime'])
        : scheduledAt;

    if (startTime == null) return false;

    final quizEnd = startTime.add(Duration(minutes: duration));
    final now = checkTime ?? DateTime.now();

    return now.isAfter(startTime) && now.isBefore(quizEnd);
  }

  Future<void> startQuizTimer(String quizId) async {
  }

  Future<bool> isSubmissionAllowed(String quizId) async {
    return true;
  }

  Future<void> updateQuiz(Quiz quiz) async {
    if (quiz.id.isEmpty) return;

    try {
      Quiz quizToUpdate = quiz;
      // Only generate automatic PIN if no manual PIN was provided AND quiz is active AND no PIN exists
      if (quiz.isActive && quiz.pinCode == null) {
        final pinResult = await _generatePinCodeWithExpiration();
        quizToUpdate = quiz.copyWith(
          pinCode: pinResult['pinCode'],
          pinExpiresAt: pinResult['expiresAt'] != null ? DateTime.parse(pinResult['expiresAt']!) : null,
        );
      } else if (quiz.isActive && quiz.pinCode != null) {
        // If manual PIN exists and quiz is active, ensure expiration time is set
        quizToUpdate = quiz.copyWith(
          pinExpiresAt: quiz.pinExpiresAt ?? DateTime.now().add(const Duration(hours: 24)),
        );
      }

      final data = quizToUpdate.toJson();
      data.remove('id');
      await _db.collection('quizzes').doc(quiz.id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating quiz: $e');
      rethrow;
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    await _db.collection('quizzes').doc(quizId).delete();
  }

  Future<void> addResult(QuizResult result) async {
    _results.add(result);
    notifyListeners();
    final docRef = await _db.collection('quiz_results').add(result.toJson());
    final quiz = _quizzes.firstWhere((q) => q.id == result.quizId, orElse: () => Quiz(
      id: result.quizId,
      title: 'Unknown Quiz',
      description: 'Quiz not found',
      subject: 'Unknown',
      questions: [],
    ));

    await _statisticsService.saveDetailedStatistics(
      result: result.copyWith(id: docRef.id),
      quiz: quiz,
    );
  }

  List<QuizResult> getResultsByQuiz(String quizId) {
    return _results.where((r) => r.quizId == quizId).toList();
  }

  Future<List<QuizResult>> getQuizResultsWithSort(String quizId) async {
    final snapshot = await _db
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => QuizResult.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<QuizResult>> getStudentResultsWithSort(String studentId) async {
    final snapshot = await _db
        .collection('quiz_results')
        .where('studentId', isEqualTo: studentId)
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => QuizResult.fromJson(doc.data(), doc.id))
        .toList();
  }
}
