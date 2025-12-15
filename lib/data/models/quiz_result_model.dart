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

  factory QuizResult.fromJson(Map<String, dynamic> json, [String? documentId]) {
    return QuizResult(
      id: json['id'] ?? documentId ?? '', // documentId может быть передан от Firestore
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

  QuizResult copyWith({
    String? id,
    String? quizId,
    String? studentId,
    String? studentName,
    int? totalPoints,
    int? maxPoints,
    double? percentage,
    DateTime? completedAt,
    List<StudentAnswer>? answers,
  }) {
    return QuizResult(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      totalPoints: totalPoints ?? this.totalPoints,
      maxPoints: maxPoints ?? this.maxPoints,
      percentage: percentage ?? this.percentage,
      completedAt: completedAt ?? this.completedAt,
      answers: answers ?? this.answers,
    );
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

  StudentAnswer copyWith({
    String? questionId,
    List<String>? selectedAnswers,
    String? textAnswer,
    bool? isCorrect,
    int? points,
    Duration? timeSpent,
  }) {
    return StudentAnswer(
      questionId: questionId ?? this.questionId,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      textAnswer: textAnswer ?? this.textAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      points: points ?? this.points,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }
}
