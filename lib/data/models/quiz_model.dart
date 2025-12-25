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
  final String? pinCode; // PIN-код для подключения
  final DateTime? pinExpiresAt; // Срок действия PIN-кода
  final bool? isQuizActive; // Дополнительное поле для активности квиза в реальном времени
  final QuizType quizType; // Тип квиза: тест на оценку по времени или самостоятельное обучение

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
    this.pinCode,
    this.pinExpiresAt,
    this.isQuizActive,
    this.quizType = QuizType.timedTest, // По умолчанию тест на оценку
  });

  factory Quiz.fromJson(Map<String, dynamic> json, [String? documentId]) {
    return Quiz(
      id: json['id'] ?? documentId ?? '', // documentId может быть передан от Firestore
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
      pinCode: json['pinCode'],
      pinExpiresAt: json['pinExpiresAt'] != null
          ? DateTime.parse(json['pinExpiresAt'])
          : null,
      isQuizActive: json['isQuizActive'],
      quizType: json['quizType'] != null
          ? QuizType.values[json['quizType']]
          : QuizType.timedTest, // По умолчанию тест на оценку
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
      if (pinCode != null) 'pinCode': pinCode,
      if (pinExpiresAt != null) 'pinExpiresAt': pinExpiresAt!.toIso8601String(),
      if (isQuizActive != null) 'isQuizActive': isQuizActive,
      'quizType': quizType.index,
    };
  }

  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    List<Question>? questions,
    int? duration,
    DateTime? scheduledAt,
    bool? isActive,
    String? ownerId,
    String? pinCode,
    DateTime? pinExpiresAt,
    bool? isQuizActive,
    QuizType? quizType,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      questions: questions ?? this.questions,
      duration: duration ?? this.duration,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isActive: isActive ?? this.isActive,
      ownerId: ownerId ?? this.ownerId,
      pinCode: pinCode ?? this.pinCode,
      pinExpiresAt: pinExpiresAt ?? this.pinExpiresAt,
      isQuizActive: isQuizActive ?? this.isQuizActive,
      quizType: quizType ?? this.quizType,
    );
  }
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<Answer> answers;
  final int points;
  final String? topic; // Тема/раздел для тематической аналитики
  final List<String>? correctTextAnswers; // Правильные варианты ответов для текстовых вопросов

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.answers,
    this.points = 1,
    this.topic,
    this.correctTextAnswers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      type: QuestionType.values[json['type']],
      answers:
          (json['answers'] as List).map((a) => Answer.fromJson(a)).toList(),
      points: json['points'] ?? 1,
      topic: json['topic'],
      correctTextAnswers: json['correctTextAnswers'] != null
          ? List<String>.from(json['correctTextAnswers'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type.index,
      'answers': answers.map((a) => a.toJson()).toList(),
      'points': points,
      if (topic != null) 'topic': topic,
      if (correctTextAnswers != null) 'correctTextAnswers': correctTextAnswers,
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

enum QuizType {
  timedTest, // Тест на оценку по времени
  selfStudy, // Самостоятельное обучение (всегда открыт)
}
