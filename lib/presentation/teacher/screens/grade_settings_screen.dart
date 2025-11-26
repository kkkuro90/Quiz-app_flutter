import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/teacher_dashboard_controller.dart';

class GradeSettingsScreen extends StatelessWidget {
  const GradeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки оценок'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Настройки оценок сохранены')),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<TeacherDashboardController>(
          builder: (context, controller, child) {
            final thresholds = controller.gradeThresholds;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Пороги оценок',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Установите минимальный процент для каждой оценки',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...thresholds.entries.map(
                  (entry) => _GradeThresholdItem(
                    grade: entry.key,
                    threshold: entry.value,
                    onChanged: (value) =>
                        controller.updateGradeThreshold(entry.key, value),
                  ),
                ),
                const SizedBox(height: 24),
                _GradeExample(
                  calculateGrade: controller.calculateGrade,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GradeThresholdItem extends StatelessWidget {
  final String grade;
  final double threshold;
  final ValueChanged<double> onChanged;

  const _GradeThresholdItem({
    required this.grade,
    required this.threshold,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getGradeColor(grade),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  grade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Оценка $grade',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Минимум: ${(threshold * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              child: Slider(
                value: threshold,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: '${(threshold * 100).toStringAsFixed(0)}%',
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeExample extends StatelessWidget {
  final String Function(double) calculateGrade;

  const _GradeExample({required this.calculateGrade});

  @override
  Widget build(BuildContext context) {
    const percentage = 0.75;
    final grade = calculateGrade(percentage);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Пример расчета',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text('Студент набрал 75% правильных ответов:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('75% правильных ответов →'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getGradeColor(grade),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      grade,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
