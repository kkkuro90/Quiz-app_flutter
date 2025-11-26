class Quiz {
  final String id;
  final String title;
  final String description;
  final String subject;
  final List<Question> questions;
  final int duration; // в минутах
  final DateTime? scheduledAt;
  final bool isActive;
  final String? ownerId;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.questions,
    this.duration = 30,
    this.scheduledAt,
    this.isActive = false,
    this.ownerId,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      subject: json['subject'],
      questions:
          (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
      duration: json['duration'],
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : null,
      isActive: json['isActive'] ?? false,
      ownerId: json['ownerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'questions': questions.map((q) => q.toJson()).toList(),
      'duration': duration,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'isActive': isActive,
      'ownerId': ownerId,
    };
  }
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<Answer> answers;
  final int points;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.answers,
    this.points = 1,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      type: QuestionType.values[json['type']],
      answers:
          (json['answers'] as List).map((a) => Answer.fromJson(a)).toList(),
      points: json['points'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.index,
      'answers': answers.map((a) => a.toJson()).toList(),
      'points': points,
    };
  }
}

class Answer {
  final String id;
  final String text;
  final bool isCorrect;

  Answer({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'],
      text: json['text'],
      isCorrect: json['isCorrect'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}

enum QuestionType {
  singleChoice,
  multipleChoice,
  textAnswer,
}
