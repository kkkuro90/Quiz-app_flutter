class Quiz {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final List<Question> questions;
  final DateTime? scheduledAt;
  final String? pinCode;
  final int duration; // in minutes
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.questions,
    this.scheduledAt,
    this.pinCode,
    this.duration = 30,
    required this.createdAt,
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? '',
      questions: (map['questions'] as List? ?? [])
          .map((q) => Question.fromMap(q))
          .toList(),
      scheduledAt: map['scheduledAt'] != null 
          ? DateTime.parse(map['scheduledAt']) 
          : null,
      pinCode: map['pinCode'],
      duration: map['duration'] ?? 30,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'questions': questions.map((q) => q.toMap()).toList(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'pinCode': pinCode,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final List<int> correctAnswers; // индексы правильных ответов
  final String type; // 'single', 'multiple', 'text'
  final int points;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswers,
    required this.type,
    this.points = 1,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswers: List<int>.from(map['correctAnswers'] ?? []),
      type: map['type'] ?? 'single',
      points: map['points'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctAnswers': correctAnswers,
      'type': type,
      'points': points,
    };
  }
}