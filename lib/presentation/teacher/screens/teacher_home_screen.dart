import 'package:flutter/material.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель учителя'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureCard(
              context,
              'Мои квизы',
              Icons.quiz,
              Colors.blue,
              onTap: () {
                _showComingSoon(context, 'Мои квизы');
              },
            ),
            _buildFeatureCard(
              context,
              'Создать квиз',
              Icons.add_circle,
              Colors.green,
              onTap: () {
                _showComingSoon(context, 'Создание квиза');
              },
            ),
            _buildFeatureCard(
              context,
              'Календарь',
              Icons.calendar_today,
              Colors.orange,
              onTap: () {
                _showComingSoon(context, 'Календарь');
              },
            ),
            _buildFeatureCard(
              context,
              'Аналитика',
              Icons.analytics,
              Colors.purple,
              onTap: () {
                _showComingSoon(context, 'Аналитика');
              },
            ),
            _buildFeatureCard(
              context,
              'Настройки оценок',
              Icons.grade,
              Colors.red,
              onTap: () {
                _showComingSoon(context, 'Настройки оценок');
              },
            ),
            _buildFeatureCard(
              context,
              'История',
              Icons.history,
              Colors.teal,
              onTap: () {
                _showComingSoon(context, 'История');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature - в разработке')),
    );
  }
}
