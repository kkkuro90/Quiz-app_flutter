import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import '../../core/services/quiz_statistics_service.dart';

/// QuizRepository: базовый Quiz API (CRUD) на Firestore
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

    // Also listen for quiz results
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
    // If quiz doesn't have a PIN and is being activated, generate a unique PIN with expiration
    Quiz quizWithPin = quiz;
    if (quiz.pinCode == null && quiz.isActive) {
      final pinResult = await _generatePinCodeWithExpiration();
      quizWithPin = quiz.copyWith(
        pinCode: pinResult['pinCode'],
        pinExpiresAt: pinResult['expiresAt'] != null ? DateTime.parse(pinResult['expiresAt']!) : null,
      );
    } else if (quiz.pinCode != null && quiz.isActive) {
      // If PIN is provided and quiz is active, set expiration
      quizWithPin = quiz.copyWith(
        pinExpiresAt: DateTime.now().add(const Duration(hours: 24)),
      );
    }

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

  /// Generate a PIN code with expiration time (24 hours by default)
  Future<Map<String, String>> _generatePinCodeWithExpiration() async {
    final pinCode = await _generateUniquePinCode();
    final expiresAt = DateTime.now().add(const Duration(hours: 24)); // PIN expires in 24 hours

    return {
      'pinCode': pinCode,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  /// Check if a PIN code is valid and not expired
  Future<bool> isValidPinCode(String pinCode) async {
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
        // Check if PIN hasn't expired yet
        return DateTime.now().isBefore(expiresAt);
      }
      // If no expiration date, assume it's valid (backward compatibility)
      return true;
    }

    return false;
  }

  /// Get quiz by PIN code, checking for validity and expiration
  Future<Quiz?> getQuizByPinCode(String pinCode) async {
    try {
      final snapshot = await _db
          .collection('quizzes')
          .where('pinCode', isEqualTo: pinCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final quiz = Quiz.fromJson(doc.data(), doc.id);

        // Check if PIN hasn't expired
        if (quiz.pinExpiresAt != null && DateTime.now().isAfter(quiz.pinExpiresAt!)) {
          // PIN has expired, return null
          return null;
        }

        return quiz;
      }
    } catch (e) {
      print('Error getting quiz by PIN: $e');
      // Return null on error to indicate quiz not found
    }

    return null;
  }

  /// Update quiz status (active/inactive)
  Future<void> updateQuizStatus(String quizId, bool isActive) async {
    final quiz = _quizzes.firstWhere((q) => q.id == quizId, orElse: () => Quiz(
      id: quizId,
      title: '',
      description: '',
      subject: '',
      questions: [],
    ));

    await _db.collection('quizzes').doc(quizId).update({
      'isQuizActive': isActive,
      'isActive': isActive, // Keep both fields for compatibility
    });

    // Update the local quiz
    if (quiz.id.isNotEmpty) {
      final updatedQuiz = quiz.copyWith(
        isQuizActive: isActive,
        isActive: isActive,
      );
      final index = _quizzes.indexWhere((q) => q.id == quizId);
      if (index != -1) {
        _quizzes[index] = updatedQuiz;
        notifyListeners();
      }
    }
  }

  /// Check if quiz is still active based on start time and duration
  Future<bool> isQuizActiveAtTime(String quizId, {DateTime? checkTime}) async {
    final doc = await _db.collection('quizzes').doc(quizId).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final scheduledAt = data['scheduledAt'] != null
        ? DateTime.parse(data['scheduledAt'])
        : null;
    final duration = data['duration'] as int? ?? 30; // Default 30 minutes
    final startTime = data['startTime'] != null
        ? DateTime.parse(data['startTime'])
        : scheduledAt; // Fallback to scheduledAt if startTime not set

    if (startTime == null) return false;

    final quizEnd = startTime.add(Duration(minutes: duration));
    final now = checkTime ?? DateTime.now();

    return now.isAfter(startTime) && now.isBefore(quizEnd);
  }

  /// Start quiz timer - sets the actual start time on the server
  Future<void> startQuizTimer(String quizId) async {
    // For now, skip this to avoid permission issues
    // Server-side timing is handled by local countdown in quiz session
  }

  /// Check if submission is allowed (within time limits)
  Future<bool> isSubmissionAllowed(String quizId) async {
    // For now, return true to avoid server-side permission issues
    // The local countdown timer in the quiz session already enforces time limits
    return true;
  }

  Future<void> updateQuiz(Quiz quiz) async {
    if (quiz.id.isEmpty) return;

    try {
      Quiz quizToUpdate = quiz;

      // If quiz is being activated and doesn't have a PIN, generate one with expiration
      if (quiz.isActive && quiz.pinCode == null) {
        final pinResult = await _generatePinCodeWithExpiration();
        quizToUpdate = quiz.copyWith(
          pinCode: pinResult['pinCode'],
          pinExpiresAt: pinResult['expiresAt'] != null ? DateTime.parse(pinResult['expiresAt']!) : null,
        );
      } else if (quiz.isActive && quiz.pinCode != null && quiz.pinExpiresAt == null) {
        // If quiz is active and has a PIN but no expiration, add expiration
        quizToUpdate = quiz.copyWith(
          pinExpiresAt: DateTime.now().add(const Duration(hours: 24)),
        );
      }

      final data = quizToUpdate.toJson();
      data.remove('id'); // Remove id field as it's the document ID, not a field
      
      // Use set with merge to ensure all fields are updated correctly
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

    // Сохраняем результат в Firestore
    final docRef = await _db.collection('quiz_results').add(result.toJson());

    // Also save detailed statistics
    final quiz = _quizzes.firstWhere((q) => q.id == result.quizId, orElse: () => Quiz(
      id: result.quizId,
      title: 'Unknown Quiz',
      description: 'Quiz not found',
      subject: 'Unknown',
      questions: [],
    ));

    await _statisticsService.saveDetailedStatistics(
      result: result.copyWith(id: docRef.id), // Use the actual Firestore document ID
      quiz: quiz,
    );
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
        .map((doc) => QuizResult.fromJson(doc.data(), doc.id))
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
        .map((doc) => QuizResult.fromJson(doc.data(), doc.id))
        .toList();
  }
}
