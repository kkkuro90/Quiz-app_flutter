import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/quiz_result_model.dart';

class QuizStatisticsService {
  final FirebaseFirestore _db;

  QuizStatisticsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> saveDetailedStatistics({
    required QuizResult result,
    required Quiz quiz,
  }) async {
    final detailedStats = _calculateDetailedStatistics(result, quiz);
    
    await _db.collection('quiz_statistics').doc(result.id).set({
      'quizId': result.quizId,
      'studentId': result.studentId,
      'resultId': result.id,
      'calculatedAt': FieldValue.serverTimestamp(),
      'detailedStats': detailedStats,
    });
  }

  Map<String, dynamic> _calculateDetailedStatistics(QuizResult result, Quiz quiz) {
    final stats = <String, dynamic>{};
    
    stats['totalQuestions'] = quiz.questions.length;
    stats['answeredQuestions'] = result.answers.length;
    stats['correctAnswers'] = result.answers.where((a) => a.isCorrect).length;
    stats['incorrectAnswers'] = result.answers.where((a) => !a.isCorrect).length;
    stats['percentage'] = result.percentage;
    
    final questionStats = <String, dynamic>{};
    for (int i = 0; i < quiz.questions.length; i++) {
      final question = quiz.questions[i];
      final answer = result.answers.firstWhere(
        (a) => a.questionId == question.id,
        orElse: () => StudentAnswer(
          questionId: question.id,
          selectedAnswers: [],
          isCorrect: false,
          points: 0,
        ),
      );
      
      questionStats[question.id] = {
        'questionText': question.text.substring(0, 
            question.text.length > 50 ? 50 : question.text.length),
        'isCorrect': answer.isCorrect,
        'pointsEarned': answer.points,
        'maxPoints': question.points,
        'timeSpent': answer.timeSpent?.inSeconds,
        'selectedAnswers': answer.selectedAnswers,
        'correctAnswers': question.answers
            .where((a) => a.isCorrect)
            .map((a) => a.id)
            .toList(),
      };
    }
    
    stats['questionStats'] = questionStats;
    
    final answerDistribution = <String, dynamic>{};
    for (final question in quiz.questions) {
      final answersForQuestion = result.answers
          .where((a) => a.questionId == question.id)
          .toList();
      
      final distribution = <String, int>{};
      for (final answer in question.answers) {
        distribution[answer.id] = answersForQuestion
            .where((res) => res.selectedAnswers.contains(answer.id))
            .length;
      }
      
      answerDistribution[question.id] = distribution;
    }
    
    stats['answerDistribution'] = answerDistribution;
    
    final easyCorrect = <String, int>{};
    final mediumCorrect = <String, int>{};
    final hardCorrect = <String, int>{};
    
    for (final question in quiz.questions) {
      final difficulty = _getDifficultyLevel(question.points);
      final isCorrect = result.answers
          .where((a) => a.questionId == question.id)
          .firstOrNull
          ?.isCorrect ?? false;
          
      switch (difficulty) {
        case 'easy':
          if (isCorrect) {
            easyCorrect['correct'] = (easyCorrect['correct'] ?? 0) + 1;
          } else {
            easyCorrect['incorrect'] = (easyCorrect['incorrect'] ?? 0) + 1;
          }
          break;
        case 'medium':
          if (isCorrect) {
            mediumCorrect['correct'] = (mediumCorrect['correct'] ?? 0) + 1;
          } else {
            mediumCorrect['incorrect'] = (mediumCorrect['incorrect'] ?? 0) + 1;
          }
          break;
        case 'hard':
          if (isCorrect) {
            hardCorrect['correct'] = (hardCorrect['correct'] ?? 0) + 1;
          } else {
            hardCorrect['incorrect'] = (hardCorrect['incorrect'] ?? 0) + 1;
          }
          break;
      }
    }
    
    stats['performanceByDifficulty'] = {
      'easy': easyCorrect,
      'medium': mediumCorrect,
      'hard': hardCorrect,
    };
    
    return stats;
  }

  String _getDifficultyLevel(int points) {
    if (points <= 1) return 'easy';
    if (points <= 3) return 'medium';
    return 'hard';
  }

  Future<Map<String, dynamic>> getQuizStatistics(String quizId) async {
    final snapshot = await _db
        .collection('quiz_statistics')
        .where('quizId', isEqualTo: quizId)
        .get();

    if (snapshot.docs.isEmpty) {
      return {'error': 'No statistics found for this quiz'};
    }
    final statsList = snapshot.docs.map((doc) => doc.data()).toList();
    return _aggregateStatistics(statsList);
  }

  Map<String, dynamic> _aggregateStatistics(List<Map<String, dynamic>> allStats) {
    if (allStats.isEmpty) return {};

    final aggregated = <String, dynamic>{};
    
    final percentages = allStats
        .map((stat) => stat['detailedStats']['percentage'] as double)
        .toList();
    
    aggregated['averagePercentage'] = percentages.reduce((a, b) => a + b) / percentages.length;
    aggregated['totalResults'] = allStats.length;
    aggregated['passRate'] = percentages.where((p) => p >= 0.5).length / percentages.length;
    
    if (allStats.isNotEmpty) {
      final firstDetailed = allStats.first['detailedStats'];
      aggregated['totalQuestions'] = firstDetailed['totalQuestions'];
      
      final questionIds = firstDetailed['questionStats'].keys.toList();
      final questionPerformance = <String, dynamic>{};
      
      for (final questionId in questionIds) {
        final correctCount = allStats.where((stat) {
          final qStat = stat['detailedStats']['questionStats'][questionId];
          return qStat != null && qStat['isCorrect'] == true;
        }).length;
        
        questionPerformance[questionId] = {
          'correctRate': correctCount / allStats.length,
          'correctCount': correctCount,
          'totalCount': allStats.length,
        };
      }
      
      aggregated['questionPerformance'] = questionPerformance;
    }
    
    return aggregated;
  }

  Future<Map<String, dynamic>> getStudentStatistics(String studentId) async {
    final snapshot = await _db
        .collection('quiz_statistics')
        .where('studentId', isEqualTo: studentId)
        .get();

    if (snapshot.docs.isEmpty) {
      return {};
    }

    final statsList = snapshot.docs.map((doc) => doc.data()).toList();
    return _aggregateStudentStatistics(statsList, studentId);
  }

  Map<String, dynamic> _aggregateStudentStatistics(List<Map<String, dynamic>> allStats, String studentId) {
    final aggregated = <String, dynamic>{};
    
    final percentages = allStats
        .map((stat) => stat['detailedStats']['percentage'] as double)
        .toList();
    
    aggregated['studentId'] = studentId;
    aggregated['totalAttempts'] = allStats.length;
    aggregated['averagePercentage'] = percentages.reduce((a, b) => a + b) / percentages.length;
    aggregated['bestResult'] = percentages.reduce((a, b) => a > b ? a : b);
    aggregated['worstResult'] = percentages.reduce((a, b) => a < b ? a : b);
    
    return aggregated;
  }
}