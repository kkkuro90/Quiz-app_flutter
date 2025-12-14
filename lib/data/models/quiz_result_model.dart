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

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'] ?? json['documentId'] ?? '', // documentId может быть передан от Firestore
      quizId: json['quizId'],
      studentId: json['studentId'],
      studentName: json['studentName'],
      totalPoints: json['totalPoints'],
      maxPoints: json['maxPoints'],
      percentage: json['percentage']?.toDouble() ?? 0.0,
      completedAt: DateTime.parse(json['completedAt']),
      answers: (json['answers'] as List)
          .map((answer) => StudentAnswer.fromJson(answer))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'totalPoints': totalPoints,
      'maxPoints': maxPoints,
      'percentage': percentage,
      'completedAt': completedAt.toIso8601String(),
      'answers': answers.map((answer) => answer.toJson()).toList(),
    };
  }

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

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    return StudentAnswer(
      questionId: json['questionId'],
      selectedAnswers: List<String>.from(json['selectedAnswers']),
      textAnswer: json['textAnswer'],
      isCorrect: json['isCorrect'],
      points: json['points'],
      timeSpent: json['timeSpentSeconds'] != null
          ? Duration(seconds: json['timeSpentSeconds'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswers': selectedAnswers,
      if (textAnswer != null) 'textAnswer': textAnswer,
      'isCorrect': isCorrect,
      'points': points,
      if (timeSpent != null) 'timeSpentSeconds': timeSpent!.inSeconds,
    };
  }
}
