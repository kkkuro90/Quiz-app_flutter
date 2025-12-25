import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/quiz_model.dart';

class QuizSchedulingService {
  final FirebaseFirestore _db;

  QuizSchedulingService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> scheduleQuiz({
    required Quiz quiz,
    required DateTime scheduledAt,
  }) async {
    await _db.collection('quizzes').doc(quiz.id).update({
      'scheduledAt': scheduledAt.toIso8601String(),
    });
  }

  Future<void> updateQuizStatus({
    required String quizId,
    required String status,
    String? statusDetails,
  }) async {
    await _db.collection('quizzes').doc(quizId).update({
      'status': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
      if (statusDetails != null) 'statusDetails': statusDetails,
    });
  }

  Future<List<Quiz>> getScheduledQuizzes({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _db
        .collection('quizzes')
        .where('scheduledAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('scheduledAt', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('scheduledAt', descending: false)
        .get();

    return snapshot.docs.map((doc) => Quiz.fromJson(doc.data(), doc.id)).toList();
  }

  Future<List<Quiz>> getQuizzesByStatus(String status) async {
    final snapshot = await _db
        .collection('quizzes')
        .where('status', isEqualTo: status)
        .get();

    return snapshot.docs.map((doc) => Quiz.fromJson(doc.data(), doc.id)).toList();
  }

  Future<void> setQuizTiming({
    required String quizId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _db.collection('quizzes').doc(quizId).update({
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    });
  }

  Future<bool> isQuizCurrentlyActive(String quizId) async {
    final doc = await _db.collection('quizzes').doc(quizId).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final scheduledAt = data['scheduledAt'] != null
        ? DateTime.parse(data['scheduledAt'])
        : null;
    final duration = data['duration'] as int? ?? 30;
    
    if (scheduledAt == null) return false;

    final quizEnd = scheduledAt.add(Duration(minutes: duration));
    final now = DateTime.now();

    return now.isAfter(scheduledAt) && now.isBefore(quizEnd);
  }
}