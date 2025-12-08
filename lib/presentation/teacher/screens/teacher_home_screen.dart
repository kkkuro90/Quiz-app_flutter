import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/app_notification_model.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/models/progress_model.dart';
import '../../../data/models/schedule_item.dart';
import '../../../data/models/study_material_model.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../shared/widgets/quiz_card.dart';
import 'calendar_screen.dart';
import 'grade_settings_screen.dart';
import 'create_quiz_screen.dart';
import 'quiz_list_screen.dart' show QuizListScreen;
import 'quiz_analytics_screen.dart';

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

        final quizRepo = context.watch<QuizRepository>();
        final activeQuizzes = quizRepo.quizzes.where((q) => q.isActive).toList();

        return Container(
          color: AppColors.background,
          child: RefreshIndicator(
            onRefresh: () async => controller.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 20),
                // Кнопка создания квиза
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateQuizScreen(),
                        ),
                      ).then((newQuiz) {
                        if (newQuiz != null && context.mounted) {
                          quizRepo.createQuiz(newQuiz);
                        }
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('📝 Создать новый квиз'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Кнопка аналитики
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuizListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('📊 Аналитика успеваемости'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                // Активные квизы
                if (activeQuizzes.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Активные квизы',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...activeQuizzes.map((quiz) {
                    final pin = _getQuizPin(quiz);
                    return QuizCard(
                      title: quiz.title,
                      subtitle: 'PIN: $pin • ${quiz.questions.length} вопросов • ${quiz.duration} мин',
                      borderColor: AppColors.primary,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              // Остановить квиз
                              quizRepo.updateQuiz(quiz.copyWith(isActive: false));
                            },
                            child: const Text('Остановить'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizAnalyticsScreen(quiz: quiz),
                                ),
                              );
                            },
                            child: const Text('Статистика'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 32),
                _buildQuickActions(context),
                const SizedBox(height: 16),
                _buildGradeConversionCard(controller, grade, gradePercentage),
                const SizedBox(height: 16),
                _buildScheduleCard(
                  controller.upcomingQuizzes,
                  controller,
                ),
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

  Widget _buildScheduleCard(
    List<ScheduleItem> schedule,
    TeacherDashboardController controller,
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
                  'Ближайшие события',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () => _showAddScheduleDialog(context, controller),
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Редактировать'),
                ),
              ],
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

  Future<void> _showAddScheduleDialog(
    BuildContext context,
    TeacherDashboardController controller,
  ) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    ScheduleItemType selectedType = ScheduleItemType.task;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Новое событие',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                    ),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      DropdownButton<ScheduleItemType>(
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(
                            value: ScheduleItemType.task,
                            child: Text('Задача'),
                          ),
                          DropdownMenuItem(
                            value: ScheduleItemType.quiz,
                            child: Text('Квиз'),
                          ),
                          DropdownMenuItem(
                            value: ScheduleItemType.material,
                            child: Text('Материал'),
                          ),
                          DropdownMenuItem(
                            value: ScheduleItemType.reminder,
                            child: Text('Напоминание'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedType = value);
                          }
                        },
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                            );
                            setState(() {
                              selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                time?.hour ?? selectedDate.hour,
                                time?.minute ?? selectedDate.minute,
                              );
                            });
                          }
                        },
                        child: Text(
                          'Дата: ${_formatDate(selectedDate)} • ${_formatTime(selectedDate)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty) {
                          Navigator.pop(ctx);
                          return;
                        }
                        controller.addScheduleItem(
                          ScheduleItem(
                            id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text,
                            description: descriptionController.text.isEmpty
                                ? 'Без описания'
                                : descriptionController.text,
                            date: selectedDate,
                            duration: const Duration(minutes: 60),
                            type: selectedType,
                          ),
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Сохранить'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
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

  String _getQuizPin(Quiz quiz) {
    // Генерация PIN на основе ID квиза (для демо)
    return (quiz.id.hashCode % 10000).toString().padLeft(4, '0');
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
