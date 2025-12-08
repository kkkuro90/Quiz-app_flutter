class QuizResult {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final int totalPoints;
  final int maxPoints;
  final double percentage;
  final DateTime completedAt;
  final List<StudentAnswer> answers;

  QuizResult({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.totalPoints,
    required this.maxPoints,
    required this.percentage,
    required this.completedAt,
    required this.answers,
  });

  String get grade {
    if (percentage >= 0.85) return '5';
    if (percentage >= 0.70) return '4';
    if (percentage >= 0.50) return '3';
    return '2';
  }
}

class StudentAnswer {
  final String questionId;
  final List<String> selectedAnswers;
  final String? textAnswer;
  final bool isCorrect;
  final int points;
  final Duration? timeSpent; // Время, затраченное на ответ

  StudentAnswer({
    required this.questionId,
    required this.selectedAnswers,
    this.textAnswer,
    required this.isCorrect,
    required this.points,
    this.timeSpent,
  });
}
