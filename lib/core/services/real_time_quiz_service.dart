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

  Stream<Quiz?> listenQuizStatus(String quizId) {
    return _db.collection('quizzes').doc(quizId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Quiz.fromJson(doc.data()!, doc.id);
    });
  }

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
    }
  }

  Future<void> updateQuizAnswers({
    required String quizId,
    required String studentId,
    required Map<String, dynamic> answers,
  }) async {
    try {
      await _db.collection('quiz_sessions').doc('$quizId-$studentId').update({
        'quizId': quizId,
        'studentId': studentId,
        'answers': answers,
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((error) async {
        await _db.collection('quiz_sessions').doc('$quizId-$studentId').set({
          'quizId': quizId,
          'studentId': studentId,
          'answers': answers,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error updating quiz answers: $e');
    }
  }

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

  void dispose() {
    _quizStatusSubscription?.cancel();
    _quizResultsSubscription?.cancel();
  }
}