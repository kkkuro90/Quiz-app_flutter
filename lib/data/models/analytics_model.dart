class SubjectPerformance {
  final String subject;
  final double averageScore; // 0..1

  const SubjectPerformance({
    required this.subject,
    required this.averageScore,
  });
}

class AnalyticsInsight {
  final String title;
  final String description;

  const AnalyticsInsight({
    required this.title,
    required this.description,
  });
}

class QuestionAnalytics {
  final String questionId;
  final String questionText;
  final double correctPercentage; // Процент правильных ответов
  final double averageTimeSeconds; // Среднее время в секундах
  final Map<String, int> answerDistribution; // Распределение выбранных вариантов
  final bool isDifficult; // Сложный вопрос (низкий % правильных)

  const QuestionAnalytics({
    required this.questionId,
    required this.questionText,
    required this.correctPercentage,
    required this.averageTimeSeconds,
    required this.answerDistribution,
    required this.isDifficult,
  });
}

class TopicPerformance {
  final String topic;
  final double averageScore; // 0..1
  final int totalQuestions;
  final int correctAnswers;

  const TopicPerformance({
    required this.topic,
    required this.averageScore,
    required this.totalQuestions,
    required this.correctAnswers,
  });
}

class QuizAnalyticsSummary {
  final double averageScore;
  final double passRate;
  final int totalAttempts;
  final SubjectPerformance? bestSubject;
  final SubjectPerformance? weakSubject;
  final List<SubjectPerformance> subjects;
  final List<AnalyticsInsight> insights;
  final List<QuestionAnalytics> questionAnalytics; // Аналитика по вопросам
  final List<TopicPerformance> topicPerformance; // Тематическая аналитика

  const QuizAnalyticsSummary({
    required this.averageScore,
    required this.passRate,
    required this.totalAttempts,
    required this.subjects,
    required this.insights,
    required this.questionAnalytics,
    required this.topicPerformance,
    this.bestSubject,
    this.weakSubject,
  });

  factory QuizAnalyticsSummary.empty() => const QuizAnalyticsSummary(
        averageScore: 0,
        passRate: 0,
        totalAttempts: 0,
        subjects: [],
        insights: [],
        questionAnalytics: [],
        topicPerformance: [],
      );
}

