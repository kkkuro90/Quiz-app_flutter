import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/colors.dart';
import '../data/repositories/auth_repository.dart';
import 'shared/widgets/gradient_background.dart';
import 'teacher/controllers/teacher_dashboard_controller.dart';
import 'teacher/screens/teacher_home_screen.dart';
import 'student/screens/student_home_screen.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthRepository>().currentUser?.role ?? 'student';
    final initialIndex = userRole == 'teacher' ? 0 : 1;

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        body: GradientBackground(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '📚 Quiz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Интерактивные квизы для образования',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Navigation
              Container(
                color: AppColors.navBackground,
                child: TabBar(
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.school),
                      text: 'Учитель',
                    ),
                    Tab(
                      icon: Icon(Icons.person),
                      text: 'Ученик',
                    ),
                    Tab(
                      icon: Icon(Icons.analytics),
                      text: 'Аналитика',
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: TabBarView(
                  children: [
                    TeacherHomeScreen(),
                    StudentHomeScreen(),
                    const _AnalyticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherDashboardController>(
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
          ],
        );
      },
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
