import 'package:flutter/material.dart';

class GradeSettingsScreen extends StatefulWidget {
  const GradeSettingsScreen({super.key});

  @override
  State<GradeSettingsScreen> createState() => _GradeSettingsScreenState();
}

class _GradeSettingsScreenState extends State<GradeSettingsScreen> {
  final Map<String, double> _gradeThresholds = {
    '5': 0.85,
    '4': 0.70,
    '3': 0.50,
    '2': 0.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки оценок'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            ..._gradeThresholds.entries.map((entry) {
              return _buildGradeThresholdItem(entry.key, entry.value);
            }),
            const SizedBox(height: 24),
            _buildGradeExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeThresholdItem(String grade, double threshold) {
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
              width: 100,
              child: Slider(
                value: threshold,
                min: 0.0,
                max: 1.0,
                divisions: 100,
                label: '${(threshold * 100).toStringAsFixed(0)}%',
                onChanged: (value) {
                  setState(() {
                    _gradeThresholds[grade] = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeExample() {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _calculateGradeColor(0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _calculateGrade(0.75),
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

  String _calculateGrade(double percentage) {
    if (percentage >= _gradeThresholds['5']!) return '5';
    if (percentage >= _gradeThresholds['4']!) return '4';
    if (percentage >= _gradeThresholds['3']!) return '3';
    return '2';
  }

  Color _calculateGradeColor(double percentage) {
    return _getGradeColor(_calculateGrade(percentage));
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки оценок сохранены')),
    );
  }
}
