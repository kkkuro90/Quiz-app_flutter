import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/app_notification_model.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/models/progress_model.dart';
import '../../../data/models/schedule_item.dart';
import '../../../data/models/study_material_model.dart';
import '../controllers/teacher_dashboard_controller.dart';
import 'calendar_screen.dart';
import 'grade_settings_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  double _earnedPoints = 75;
  double _maxPoints = 100;

  @override
  Widget build(BuildContext context) {
    return Consumer<TeacherDashboardController>(
      builder: (context, controller, child) {
        final gradePercentage =
            _maxPoints == 0 ? 0.0 : (_earnedPoints / _maxPoints);
        final grade = controller.calculateGrade(gradePercentage);
        final analytics = controller.analyticsSummary;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Панель учителя'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.refresh,
                tooltip: 'Обновить данные',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => controller.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildQuickActions(context),
                const SizedBox(height: 16),
                _buildFinancialModule(controller),
                const SizedBox(height: 16),
                _buildGradeConversionCard(controller, grade, gradePercentage),
                const SizedBox(height: 16),
                _buildScheduleCard(controller.upcomingQuizzes),
                const SizedBox(height: 16),
                _buildProgressCard(controller.progressMetrics),
                const SizedBox(height: 16),
                _buildMaterialsCard(controller.materials),
                const SizedBox(height: 16),
                _buildNotificationsCard(
                  controller.notifications,
                  onMarkAllRead: controller.markAllNotificationsAsRead,
                  onMarkRead: controller.markNotificationAsRead,
                ),
                const SizedBox(height: 16),
                _buildAnalyticsCard(analytics),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'Календарь',
            icon: Icons.calendar_today,
            color: Colors.orange,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CalendarScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            label: 'Оценки',
            icon: Icons.grade,
            color: Colors.blue,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const GradeSettingsScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            label: 'Режим ученика',
            icon: Icons.swap_horiz,
            color: Colors.green,
            onTap: () {
              DefaultTabController.of(context).animateTo(1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialModule(TeacherDashboardController controller) {
    final metrics = controller.financialMetrics;

    Widget buildStat(String label, double value, {Color? color}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(0)} ₽',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Финансовый модуль',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                buildStat('Доходы', metrics.totalIncome, color: Colors.green),
                buildStat('Расходы', metrics.totalExpenses, color: Colors.red),
                buildStat('Чистая прибыль', metrics.netProfit),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  metrics.trendPercentage >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: metrics.trendPercentage >= 0
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '${metrics.trendPercentage >= 0 ? '+' : ''}${metrics.trendPercentage.toStringAsFixed(1)}% к прошлому периоду',
                  style: TextStyle(
                    color: metrics.trendPercentage >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                const Spacer(),
                Text(
                  'Прогноз: ${metrics.monthlyProjection.toStringAsFixed(0)} ₽/мес',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeConversionCard(
    TeacherDashboardController controller,
    String grade,
    double percentage,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Конвертация баллов',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Chip(
                  label: Text(
                    'Оценка $grade',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _gradeColor(grade),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSliderRow(
              label: 'Набрано баллов',
              value: _earnedPoints,
              max: 100,
              onChanged: (value) => setState(() => _earnedPoints = value),
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: 'Максимум баллов',
              value: _maxPoints,
              max: 120,
              onChanged: (value) => setState(() => _maxPoints = value),
            ),
            const SizedBox(height: 12),
            Text(
              'Процент: ${(percentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Пороги оценок: ${controller.gradeThresholds.entries.map((e) => '${e.key} ≥ ${(e.value * 100).toStringAsFixed(0)}%').join(', ')}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label),
        ),
        Expanded(
          child: Slider(
            value: value,
            max: max,
            divisions: max.toInt(),
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(value.toStringAsFixed(0)),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(List<ScheduleItem> schedule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ближайшие события',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (schedule.isEmpty)
              const Text('Расписание пустое на ближайшую неделю')
            else
              ...schedule.take(4).map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _scheduleColor(item.type),
                    child: Icon(
                      item.type == ScheduleItemType.quiz
                          ? Icons.quiz
                          : Icons.event_note,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${_formatDate(item.date)} • ${item.description}',
                  ),
                  trailing: Text(
                    _formatTime(item.date),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(List<ProgressMetric> metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Прогресс обучения',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...metrics.map((metric) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(metric.subject),
                        Text(
                          '${(metric.completion * 100).toStringAsFixed(0)}% • ${metric.trendLabel}',
                          style: TextStyle(
                            color: metric.weeklyDelta >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: metric.completion,
                      minHeight: 8,
                      color: metric.completion > 0.75
                          ? Colors.green
                          : Colors.orange,
                      backgroundColor: Colors.grey[200],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsCard(List<StudyMaterial> materials) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Лекции и материалы',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...materials.map(
              (material) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_materialIcon(material.type)),
                title: Text(material.title),
                subtitle: Text(
                  '${material.subject} • обновлено ${_formatDate(material.updatedAt)}',
                ),
                trailing: Text(material.format.toUpperCase()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard(
    List<AppNotification> notifications, {
    required VoidCallback onMarkAllRead,
    required Function(String) onMarkRead,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Уведомления',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: onMarkAllRead,
                  child: const Text('Прочитать все'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              const Text('Новых уведомлений нет')
            else
              ...notifications.take(4).map(
                (notification) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _notificationIcon(notification.type),
                    color: _notificationColor(notification.type),
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                  trailing: notification.isRead
                      ? const Icon(Icons.check, color: Colors.green)
                      : TextButton(
                          onPressed: () => onMarkRead(notification.id),
                          child: const Text('Прочитать'),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(QuizAnalyticsSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Анализ результатов',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AnalyticsStat(
                    label: 'Средний балл',
                    value: '${(summary.averageScore * 100).toStringAsFixed(1)}%',
                  ),
                ),
                Expanded(
                  child: _AnalyticsStat(
                    label: 'Процент сдачи',
                    value: '${(summary.passRate * 100).toStringAsFixed(1)}%',
                  ),
                ),
                Expanded(
                  child: _AnalyticsStat(
                    label: 'Попытки',
                    value: summary.totalAttempts.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (summary.subjects.isEmpty)
              const Text('Недостаточно данных для аналитики')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summary.bestSubject != null)
                    Text(
                      'Сильная сторона: ${summary.bestSubject!.subject} (${(summary.bestSubject!.averageScore * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(color: Colors.green),
                    ),
                  if (summary.weakSubject != null)
                    Text(
                      'Зона роста: ${summary.weakSubject!.subject} (${(summary.weakSubject!.averageScore * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  const SizedBox(height: 8),
                  ...summary.insights.map(
                    (insight) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.insights, color: Colors.blue),
                      title: Text(insight.title),
                      subtitle: Text(insight.description),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  IconData _materialIcon(StudyMaterialType type) {
    switch (type) {
      case StudyMaterialType.lecture:
        return Icons.menu_book;
      case StudyMaterialType.presentation:
        return Icons.slideshow;
      case StudyMaterialType.document:
        return Icons.description;
      case StudyMaterialType.video:
        return Icons.play_circle;
      case StudyMaterialType.homework:
        return Icons.assignment;
    }
  }

  IconData _notificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.quiz:
        return Icons.quiz;
      case NotificationType.reminder:
        return Icons.notifications_active;
      case NotificationType.material:
        return Icons.folder;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _notificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.quiz:
        return Colors.purple;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.material:
        return Colors.blue;
      case NotificationType.system:
        return Colors.green;
    }
  }

  Color _scheduleColor(ScheduleItemType type) {
    switch (type) {
      case ScheduleItemType.quiz:
        return Colors.purple;
      case ScheduleItemType.task:
        return Colors.blue;
      case ScheduleItemType.reminder:
        return Colors.orange;
      case ScheduleItemType.material:
        return Colors.green;
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsStat extends StatelessWidget {
  final String label;
  final String value;

  const _AnalyticsStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
