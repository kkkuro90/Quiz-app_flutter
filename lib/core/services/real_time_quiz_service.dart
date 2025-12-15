import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../data/models/quiz_model.dart';
import '../../data/models/quiz_result_model.dart';

class RealTimeQuizService {
  final FirebaseFirestore _db;
  StreamSubscription? _quizStatusSubscription;
  StreamSubscription? _quizResultsSubscription;

  RealTimeQuizService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Listen for quiz status changes (active/inactive, start/end)
  Stream<Quiz?> listenQuizStatus(String quizId) {
    return _db.collection('quizzes').doc(quizId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Quiz.fromJson(doc.data()!, doc.id);
    });
  }

  /// Listen for real-time quiz results updates
  Stream<List<QuizResult>> listenQuizResults(String quizId) {
    return _db
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return QuizResult.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Update quiz status in real-time
  Future<void> updateQuizStatus({
    required String quizId,
    required String status,
    String? statusDetails,
  }) async {
    try {
      await _db.collection('quizzes').doc(quizId).update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        if (statusDetails != null) 'statusDetails': statusDetails,
      });
    } catch (e) {
      print('Error updating quiz status: $e');
      // Silently handle the error to not break the quiz experience
    }
  }

  /// Update quiz in-progress answers or results
  Future<void> updateQuizAnswers({
    required String quizId,
    required String studentId,
    required Map<String, dynamic> answers,
  }) async {
    try {
      // Create or update a document for the student's current answers
      await _db.collection('quiz_sessions').doc('$quizId-$studentId').update({
        'quizId': quizId,
        'studentId': studentId,
        'answers': answers,
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((error) async {
        // If the document doesn't exist, create it
        await _db.collection('quiz_sessions').doc('$quizId-$studentId').set({
          'quizId': quizId,
          'studentId': studentId,
          'answers': answers,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error updating quiz answers: $e');
      // Silently handle the error to not break the quiz experience
    }
  }

  /// Listen for individual student's answers during quiz
  Stream<Map<String, dynamic>?> listenStudentAnswers({
    required String quizId,
    required String studentId,
  }) {
    return _db
        .collection('quiz_sessions')
        .doc('$quizId-$studentId')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      return data?['answers'] as Map<String, dynamic>?;
    });
  }

  /// Stop all active subscriptions
  void dispose() {
    _quizStatusSubscription?.cancel();
    _quizResultsSubscription?.cancel();
  }
}