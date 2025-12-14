import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../controllers/teacher_dashboard_controller.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика успеваемости'),
      ),
      body: Consumer<TeacherDashboardController>(
        builder: (context, controller, _) {
          final summary = controller.analyticsSummary;

          if (summary.totalAttempts == 0) {
            return const Center(
              child: Text('Данных для аналитики пока нет'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  _StatCard(
                    label: 'Средний балл',
                    value: '${(summary.averageScore * 100).toStringAsFixed(1)}%',
                    icon: Icons.grade,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Процент сдачи',
                    value: '${(summary.passRate * 100).toStringAsFixed(1)}%',
                    icon: Icons.verified,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Попытки',
                    value: summary.totalAttempts.toString(),
                    icon: Icons.repeat,
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (summary.subjects.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'По предметам',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...summary.subjects.map(
                          (s) => ListTile(
                            leading: Icon(
                              Icons.bookmark,
                              color: s == summary.bestSubject
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            title: Text(s.subject),
                            trailing: Text(
                              '${(s.averageScore * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (summary.insights.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Инсайты',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...summary.insights.map(
                          (insight) => ListTile(
                            leading: const Icon(Icons.insights, color: Colors.blue),
                            title: Text(insight.title),
                            subtitle: Text(insight.description),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Аналитика по вопросам
              if (summary.questionAnalytics.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Аналитика по вопросам',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...summary.questionAnalytics.take(10).map(
                          (qa) => ExpansionTile(
                            title: Text(
                              qa.questionText.length > 50
                                  ? '${qa.questionText.substring(0, 50)}...'
                                  : qa.questionText,
                              style: TextStyle(
                                fontWeight: qa.isDifficult ? FontWeight.bold : FontWeight.normal,
                                color: qa.isDifficult ? Colors.red : null,
                              ),
                            ),
                            subtitle: Text(
                              'Правильных: ${(qa.correctPercentage * 100).toStringAsFixed(1)}% • '
                              'Время: ${qa.averageTimeSeconds.toStringAsFixed(1)}с',
                            ),
                            leading: Icon(
                              qa.isDifficult ? Icons.warning : Icons.check_circle,
                              color: qa.isDifficult ? Colors.red : Colors.green,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Полный текст вопроса:',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(qa.questionText),
                                    const SizedBox(height: 12),
                                    if (qa.answerDistribution.isNotEmpty) ...[
                                      Text(
                                        'Распределение ответов:',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      ...qa.answerDistribution.entries.map(
                                        (entry) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: LinearProgressIndicator(
                                                  value: entry.value / qa.answerDistribution.values.reduce((a, b) => a > b ? a : b),
                                                  backgroundColor: Colors.grey[200],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${entry.value}',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Тематическая аналитика
              if (summary.topicPerformance.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Тематическая аналитика',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Тепловая карта знаний',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: summary.topicPerformance.map(
                            (tp) => _TopicChip(
                              topic: tp.topic,
                              score: tp.averageScore,
                              totalQuestions: tp.totalQuestions,
                              correctAnswers: tp.correctAnswers,
                            ),
                          ).toList(),
                        ),
                        const SizedBox(height: 16),
                        ...summary.topicPerformance.map(
                          (tp) => ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getTopicColor(tp.averageScore),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${(tp.averageScore * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(tp.topic),
                            subtitle: Text(
                              'Правильных ответов: ${tp.correctAnswers} из ${tp.totalQuestions}',
                            ),
                            trailing: LinearProgressIndicator(
                              value: tp.averageScore,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              color: _getTopicColor(tp.averageScore),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String topic;
  final double score;
  final int totalQuestions;
  final int correctAnswers;

  const _TopicChip({
    required this.topic,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getTopicColor(score).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getTopicColor(score),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topic,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getTopicColor(score),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: _getTopicColor(score),
            ),
          ),
        ],
      ),
    );
  }
}

Color _getTopicColor(double score) {
  if (score >= 0.8) return Colors.green;
  if (score >= 0.6) return Colors.lightGreen;
  if (score >= 0.4) return Colors.orange;
  return Colors.red;
}

