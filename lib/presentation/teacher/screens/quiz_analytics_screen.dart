import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../data/models/quiz_model.dart';
import '../../../data/models/quiz_result_model.dart';
import '../../../data/repositories/quiz_repository.dart';

class QuizAnalyticsScreen extends StatelessWidget {
  final Quiz quiz;

  const QuizAnalyticsScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final quizRepo = context.watch<QuizRepository>();
    final results = quizRepo.getResultsByQuiz(quiz.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Аналитика: ${quiz.title}'),
      ),
      body: results.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет данных для анализа',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(context, results), // ← ДОБАВЛЕН context
                  const SizedBox(height: 24),
                  _buildScoreDistributionChart(
                      context, results), // ← ДОБАВЛЕН context
                  const SizedBox(height: 24),
                  _buildResultsList(context, results), // ← ДОБАВЛЕН context
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<QuizResult> results) {
    // ← ДОБАВЛЕН параметр
    final averageScore =
        results.map((r) => r.percentage).reduce((a, b) => a + b) /
            results.length;
    final bestScore =
        results.map((r) => r.percentage).reduce((a, b) => a > b ? a : b);
    // final worstScore = // ← ЗАКОММЕНТИРОВАНО, т.к. не используется
    //     results.map((r) => r.percentage).reduce((a, b) => a < b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Общая статистика',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Участники', '${results.length}'),
                _buildStatItem('Средний балл',
                    '${(averageScore * 100).toStringAsFixed(1)}%'),
                _buildStatItem('Лучший результат',
                    '${(bestScore * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildScoreDistributionChart(
      BuildContext context, List<QuizResult> results) {
    // ← ДОБАВЛЕН параметр
    final scoreRanges = {
      '0-49%': 0,
      '50-69%': 0,
      '70-84%': 0,
      '85-100%': 0,
    };

    for (final result in results) {
      final percentage = result.percentage * 100;
      if (percentage < 50) {
        scoreRanges['0-49%'] = scoreRanges['0-49%']! + 1;
      } else if (percentage < 70) {
        scoreRanges['50-69%'] = scoreRanges['50-69%']! + 1;
      } else if (percentage < 85) {
        scoreRanges['70-84%'] = scoreRanges['70-84%']! + 1;
      } else {
        scoreRanges['85-100%'] = scoreRanges['85-100%']! + 1;
      }
    }

    final chartData = scoreRanges.entries.map((entry) {
      return _ChartData(entry.key, entry.value);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Распределение оценок',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                series: <ColumnSeries<_ChartData, String>>[
                  ColumnSeries<_ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (_ChartData data, _) => data.range,
                    yValueMapper: (_ChartData data, _) => data.count,
                    color: Colors.blue,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, List<QuizResult> results) {
    // ← ДОБАВЛЕН параметр
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Результаты учеников',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...results.map((result) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getGradeColor(result.grade),
                  child: Text(
                    result.grade,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(result.studentName),
                subtitle: Text(
                  '${result.totalPoints}/${result.maxPoints} баллов • ${(result.percentage * 100).toStringAsFixed(1)}%',
                ),
                trailing: Text(
                  _formatDate(result.completedAt),
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case '5':
        return Colors.green;
      case '4':
        return Colors.blue;
      case '3':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _ChartData {
  final String range;
  final int count;

  _ChartData(this.range, this.count);
}
