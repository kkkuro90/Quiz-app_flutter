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
                Text(
                  'Пороги оценок',
                  style: Theme.of(context).textTheme.titleLarge,
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
