import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/services/notification_service.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/models/app_notification_model.dart';
import '../../../data/models/financial_model.dart';
import '../../../data/models/progress_model.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/models/quiz_result_model.dart';
import '../../../data/models/schedule_item.dart';
import '../../../data/models/study_material_model.dart';
import '../../../data/repositories/quiz_repository.dart';

class TeacherDashboardController extends ChangeNotifier {
  TeacherDashboardController({
    required QuizRepository quizRepository,
    required NotificationService notificationService,
  })  : _quizRepository = quizRepository,
        _notificationService = notificationService {
    _init();
  }

  QuizRepository _quizRepository;
  NotificationService _notificationService;

  List<FinancialRecord> _financialRecords = [];
  List<ScheduleItem> _schedule = [];
  List<StudyMaterial> _materials = [];
  List<ProgressMetric> _progressMetrics = [];
  QuizAnalyticsSummary _analyticsSummary = QuizAnalyticsSummary.empty();
  final Map<String, double> _gradeThresholds = {
    '5': 0.85,
    '4': 0.70,
    '3': 0.50,
    '2': 0.0,
  };

  List<AppNotification> get notifications =>
      _notificationService.notifications;
  List<StudyMaterial> get materials => List.unmodifiable(_materials);
  List<ScheduleItem> get schedule => List.unmodifiable(_schedule);
  List<ProgressMetric> get progressMetrics =>
      List.unmodifiable(_progressMetrics);
  FinancialMetrics get financialMetrics =>
      FinancialCalculator.calculateMetrics(_financialRecords);
  Map<String, double> get gradeThresholds => Map.unmodifiable(_gradeThresholds);
  QuizAnalyticsSummary get analyticsSummary => _analyticsSummary;

  List<ScheduleItem> get upcomingQuizzes => _schedule
      .where((item) =>
          item.type == ScheduleItemType.quiz &&
          item.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
      .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  void _init() {
    _quizRepository.addListener(_onRepositoryChanged);
    _bootstrapData();
  }

  void updateSources(
    QuizRepository quizRepository,
    NotificationService notificationService,
  ) {
    if (_quizRepository == quizRepository &&
        _notificationService == notificationService) {
      return;
    }
    _quizRepository.removeListener(_onRepositoryChanged);
    _quizRepository = quizRepository;
    _notificationService = notificationService;
    _quizRepository.addListener(_onRepositoryChanged);
    _bootstrapData();
  }

  @override
  void dispose() {
    _quizRepository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void refresh() {
    _bootstrapData();
  }

  void addStudyMaterial(StudyMaterial material) {
    _materials.add(material);
    notifyListeners();
  }

  void addScheduleItem(ScheduleItem item) {
    _schedule.add(item);
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    _notificationService.markAsRead(id);
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    _notificationService.markAllAsRead();
    notifyListeners();
  }

  void updateGradeThreshold(String grade, double value) {
    _gradeThresholds[grade] = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  String calculateGrade(double percentage) {
    if (percentage >= _gradeThresholds['5']!) return '5';
    if (percentage >= _gradeThresholds['4']!) return '4';
    if (percentage >= _gradeThresholds['3']!) return '3';
    return '2';
  }

  void _bootstrapData() {
    _schedule = _buildSchedule();
    _materials = _buildMaterials();
    _financialRecords = _buildFinancialRecords();
    _progressMetrics = _buildProgress();
    _analyticsSummary = _buildAnalyticsSummary();
    _syncNotifications();
    notifyListeners();
  }

  void _onRepositoryChanged() {
    _bootstrapData();
  }

  List<ScheduleItem> _buildSchedule() {
    final quizzes = _quizRepository.quizzes;
    final items = <ScheduleItem>[];

    for (final quiz in quizzes.where((q) => q.scheduledAt != null)) {
      final scheduledAt = quiz.scheduledAt!;
      items.add(
        ScheduleItem(
          id: 'quiz-${quiz.id}',
          title: quiz.title,
          description: quiz.description,
          date: scheduledAt,
          duration: Duration(minutes: quiz.duration),
          type: ScheduleItemType.quiz,
          relatedQuizId: quiz.id,
        ),
      );
      items.add(
        ScheduleItem(
          id: 'prep-${quiz.id}',
          title: 'Подготовить материалы: ${quiz.subject}',
          description: 'Проверить вопросы и опубликовать материалы студентам',
          date: scheduledAt.subtract(const Duration(days: 1)),
          type: ScheduleItemType.task,
          relatedQuizId: quiz.id,
        ),
      );
    }

    items.addAll([
      ScheduleItem(
        id: 'task-budget',
        title: 'Обновить финансовый план',
        description: 'Сверка бюджета за текущую неделю',
        date: DateTime.now().add(const Duration(days: 1, hours: 3)),
        type: ScheduleItemType.task,
      ),
      ScheduleItem(
        id: 'task-mentor',
        title: 'Лекция: подготовка к Олимпиаде',
        description: 'Загрузить презентацию и материалы для команды',
        date: DateTime.now().add(const Duration(days: 3, hours: 2)),
        type: ScheduleItemType.material,
      ),
    ]);

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  List<StudyMaterial> _buildMaterials() {
    // Материалы теперь динамические - добавляются через addStudyMaterial
    // или могут быть загружены из базы данных
    return [];
  }

  List<FinancialRecord> _buildFinancialRecords() {
    final quizzes = _quizRepository.quizzes;
    final rng = Random(7);

    return quizzes.map((quiz) {
      final plannedIncome = 10000 + rng.nextInt(5000);
      final actualIncome = plannedIncome - rng.nextInt(2000);
      final expenses = 2000 + rng.nextInt(1500);

      return FinancialRecord(
        id: 'fin-${quiz.id}',
        quizId: quiz.id,
        quizTitle: quiz.title,
        period: quiz.scheduledAt ?? DateTime.now(),
        plannedIncome: plannedIncome.toDouble(),
        actualIncome: actualIncome.toDouble(),
        expenses: expenses.toDouble(),
      );
    }).toList();
  }

  List<ProgressMetric> _buildProgress() {
    final subjectScores = <String, List<double>>{};
    final results = _quizRepository.results;
    final quizzesById = {
      for (final quiz in _quizRepository.quizzes) quiz.id: quiz
    };

    for (final result in results) {
      final quiz = quizzesById[result.quizId];
      if (quiz == null) continue;
      subjectScores.putIfAbsent(quiz.subject, () => []);
      subjectScores[quiz.subject]!.add(result.percentage);
    }

    if (subjectScores.isEmpty) {
      return [
        const ProgressMetric(subject: 'Математика', completion: 0.6, weeklyDelta: 0.05),
        const ProgressMetric(subject: 'Физика', completion: 0.55, weeklyDelta: -0.02),
      ];
    }

    return subjectScores.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      final delta = (Random(entry.key.hashCode).nextDouble() * 0.1) - 0.05;
      return ProgressMetric(
        subject: entry.key,
        completion: avg,
        weeklyDelta: delta,
      );
    }).toList();
  }

  QuizAnalyticsSummary _buildAnalyticsSummary() {
    final results = _quizRepository.results;
    if (results.isEmpty) {
      return QuizAnalyticsSummary.empty();
    }

    final averageScore =
        results.map((r) => r.percentage).reduce((a, b) => a + b) /
            results.length;
    final passThreshold = _gradeThresholds['3'] ?? 0.5;
    final passRate = results
            .where((r) => r.percentage >= passThreshold)
            .length /
        results.length;

    final subjectStats = <String, List<double>>{};
    final quizzesById = {
      for (final quiz in _quizRepository.quizzes) quiz.id: quiz
    };

    for (final result in results) {
      final quiz = quizzesById[result.quizId];
      if (quiz == null) continue;
      subjectStats.putIfAbsent(quiz.subject, () => []);
      subjectStats[quiz.subject]!.add(result.percentage);
    }

    final subjectPerformance = subjectStats.entries.map((entry) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return SubjectPerformance(subject: entry.key, averageScore: avg);
    }).toList()
      ..sort((a, b) => b.averageScore.compareTo(a.averageScore));

    final insights = <AnalyticsInsight>[];
    if (subjectPerformance.isNotEmpty) {
      insights.add(
        AnalyticsInsight(
          title: 'Сильная сторона',
          description:
              '${subjectPerformance.first.subject}: ${(subjectPerformance.first.averageScore * 100).toStringAsFixed(1)}%',
        ),
      );
      if (subjectPerformance.length > 1) {
        insights.add(
          AnalyticsInsight(
            title: 'Зона роста',
            description:
                '${subjectPerformance.last.subject}: ${(subjectPerformance.last.averageScore * 100).toStringAsFixed(1)}%',
          ),
        );
      }
    }

    // Аналитика по вопросам
    final questionAnalytics = _buildQuestionAnalytics(results, quizzesById);
    
    // Тематическая аналитика
    final topicPerformance = _buildTopicAnalytics(results, quizzesById);

    return QuizAnalyticsSummary(
      averageScore: averageScore,
      passRate: passRate,
      totalAttempts: results.length,
      subjects: subjectPerformance,
      insights: insights,
      questionAnalytics: questionAnalytics,
      topicPerformance: topicPerformance,
      bestSubject: subjectPerformance.isNotEmpty ? subjectPerformance.first : null,
      weakSubject: subjectPerformance.length > 1 ? subjectPerformance.last : null,
    );
  }

  List<QuestionAnalytics> _buildQuestionAnalytics(
    List<QuizResult> results,
    Map<String, Quiz> quizzesById,
  ) {
    final questionStats = <String, _QuestionStats>{};

    for (final result in results) {
      final quiz = quizzesById[result.quizId];
      if (quiz == null) continue;

      for (final answer in result.answers) {
        final question = quiz.questions.where((q) => q.id == answer.questionId).firstOrNull;
        if (question == null) continue;

        final stats = questionStats.putIfAbsent(
          answer.questionId,
          () => _QuestionStats(
            questionId: answer.questionId,
            questionText: question.text,
          ),
        );

        stats.totalAttempts++;
        if (answer.isCorrect) {
          stats.correctAttempts++;
        }

        // Время, затраченное на ответ
        if (answer.timeSpent != null) {
          stats.totalTimeSeconds += answer.timeSpent!.inSeconds;
          stats.timeCount++;
        }

        // Распределение выбранных вариантов
        for (final selectedId in answer.selectedAnswers) {
          stats.answerDistribution[selectedId] =
              (stats.answerDistribution[selectedId] ?? 0) + 1;
        }
      }
    }

    return questionStats.values.map((stats) {
      final correctPercentage = stats.totalAttempts > 0
          ? stats.correctAttempts / stats.totalAttempts
          : 0.0;
      final averageTime = stats.timeCount > 0
          ? stats.totalTimeSeconds / stats.timeCount
          : 0.0;
      final isDifficult = correctPercentage < 0.5; // Менее 50% правильных ответов

      return QuestionAnalytics(
        questionId: stats.questionId,
        questionText: stats.questionText,
        correctPercentage: correctPercentage,
        averageTimeSeconds: averageTime,
        answerDistribution: stats.answerDistribution,
        isDifficult: isDifficult,
      );
    }).toList()
      ..sort((a, b) => a.correctPercentage.compareTo(b.correctPercentage));
  }

  List<TopicPerformance> _buildTopicAnalytics(
    List<QuizResult> results,
    Map<String, Quiz> quizzesById,
  ) {
    final topicStats = <String, _TopicStats>{};

    for (final result in results) {
      final quiz = quizzesById[result.quizId];
      if (quiz == null) continue;

      for (final answer in result.answers) {
        final question = quiz.questions.where((q) => q.id == answer.questionId).firstOrNull;
        if (question == null) continue;

        final topic = question.topic ?? 'Без темы';
        final stats = topicStats.putIfAbsent(
          topic,
          () => _TopicStats(topic: topic),
        );

        stats.totalQuestions++;
        if (answer.isCorrect) {
          stats.correctAnswers++;
        }
      }
    }

    return topicStats.values.map((stats) {
      final averageScore = stats.totalQuestions > 0
          ? stats.correctAnswers / stats.totalQuestions
          : 0.0;

      return TopicPerformance(
        topic: stats.topic,
        averageScore: averageScore,
        totalQuestions: stats.totalQuestions,
        correctAnswers: stats.correctAnswers,
      );
    }).toList()
      ..sort((a, b) => b.averageScore.compareTo(a.averageScore));
  }

  void _syncNotifications() {
    final notifications = <AppNotification>[
      AppNotification(
        id: 'notify-progress',
        title: 'Обновлена статистика прогресса',
        message:
            'Средний балл по математике вырос на ${(_progressMetrics.firstOrNull?.weeklyDelta ?? 0).abs().toStringAsFixed(2)}%',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        type: NotificationType.system,
      ),
    ];

    for (final quiz in _quizRepository.quizzes.where((q) => q.scheduledAt != null)) {
      notifications.add(
        AppNotification(
          id: 'notify-${quiz.id}',
          title: 'Новый тест запланирован',
          message:
              '${quiz.title} пройдет ${quiz.scheduledAt!.day}.${quiz.scheduledAt!.month} в ${quiz.scheduledAt!.hour.toString().padLeft(2, '0')}:${quiz.scheduledAt!.minute.toString().padLeft(2, '0')}',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          type: NotificationType.quiz,
        ),
      );
    }

    _notificationService.seed(notifications);
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _QuestionStats {
  final String questionId;
  final String questionText;
  int totalAttempts = 0;
  int correctAttempts = 0;
  double totalTimeSeconds = 0;
  int timeCount = 0;
  final Map<String, int> answerDistribution = {};

  _QuestionStats({
    required this.questionId,
    required this.questionText,
  });
}

class _TopicStats {
  final String topic;
  int totalQuestions = 0;
  int correctAnswers = 0;

  _TopicStats({required this.topic});
}

