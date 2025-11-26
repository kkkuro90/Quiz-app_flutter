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

class QuizAnalyticsSummary {
  final double averageScore;
  final double passRate;
  final int totalAttempts;
  final SubjectPerformance? bestSubject;
  final SubjectPerformance? weakSubject;
  final List<SubjectPerformance> subjects;
  final List<AnalyticsInsight> insights;

  const QuizAnalyticsSummary({
    required this.averageScore,
    required this.passRate,
    required this.totalAttempts,
    required this.subjects,
    required this.insights,
    this.bestSubject,
    this.weakSubject,
  });

  factory QuizAnalyticsSummary.empty() => const QuizAnalyticsSummary(
        averageScore: 0,
        passRate: 0,
        totalAttempts: 0,
        subjects: [],
        insights: [],
      );
}

