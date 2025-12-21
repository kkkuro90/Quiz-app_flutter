import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../core/services/export_service.dart';
import 'create_quiz_screen.dart';
import 'quiz_analytics_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final quizRepo = context.watch<QuizRepository>();
    final now = DateTime.now();

    final filteredQuizzes = quizRepo.quizzes.where((quiz) {
      switch (_selectedFilter) {
        case 'active':
          return quiz.isActive;
        case 'scheduled':
          return quiz.scheduledAt != null && quiz.scheduledAt!.isAfter(now);
        case 'all':
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои квизы'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Все квизы')),
              const PopupMenuItem(value: 'active', child: Text('Активные')),
              const PopupMenuItem(
                  value: 'scheduled', child: Text('Запланированные')),
            ],
          ),
        ],
      ),
      body: filteredQuizzes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Пока нет созданных квизов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: filteredQuizzes.length,
              itemBuilder: (context, index) {
                final quiz = filteredQuizzes[index];
                return QuizCard(quiz: quiz);
              },
            ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
      ),
    );
  }
}

class QuizCard extends StatelessWidget {
  final Quiz quiz;

  const QuizCard({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final quizRepo = context.read<QuizRepository>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quiz.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleMenuAction(value, context, quizRepo);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Редактировать'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'analytics',
                      child: ListTile(
                        leading: Icon(Icons.analytics),
                        title: Text('Аналитика'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.import_export), // ← ИСПРАВЛЕНО
                        title: Text('Экспорт'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Удалить',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(quiz.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(quiz.subject),
                  backgroundColor: Colors.blue[50],
                ),
                Chip(
                  label: Text('${quiz.questions.length} вопросов'),
                  backgroundColor: Colors.green[50],
                ),
                Chip(
                  label: Text('${quiz.duration} мин'),
                  backgroundColor: Colors.orange[50],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _startQuiz(context, quiz, quizRepo);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Запустить'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _scheduleQuiz(context, quiz, quizRepo);
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Запланировать'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
      String value, BuildContext context, QuizRepository quizRepo) {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateQuizScreen(quiz: quiz),
          ),
        ).then((updatedQuiz) {
          if (updatedQuiz != null && context.mounted) {
            quizRepo.updateQuiz(updatedQuiz);
          }
        });
        break;
      case 'analytics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizAnalyticsScreen(quiz: quiz),
          ),
        );
        break;
      case 'export':
        _exportQuiz(context);
        break;
      case 'delete':
        _deleteQuiz(context, quizRepo);
        break;
    }
  }

  void _startQuiz(BuildContext context, Quiz quiz, QuizRepository quizRepo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Запуск квиза'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Квиз: ${quiz.title}'),
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'PIN-код для учеников',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateTime.now().millisecondsSinceEpoch % 10000}'
                          .padLeft(4, '0'),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (context.mounted) {
                // Обновляем статус квиза как активный
                quizRepo.updateQuiz(quiz.copyWith(isActive: true));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Квиз запущен!')),
                );
              }
            },
            child: const Text('Запустить'),
          ),
        ],
      ),
    );
  }

  void _scheduleQuiz(BuildContext context, Quiz quiz, QuizRepository quizRepo) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
<<<<<<< HEAD
    ).then((selectedDate) async {
      if (selectedDate != null && context.mounted) {
        // Show time picker after date is selected
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (time != null && context.mounted) {
          // Combine date and time
          final scheduledAt = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            time.hour,
            time.minute,
          );

          // Update the quiz in the repository with the scheduled time
          final updatedQuiz = quiz.copyWith(scheduledAt: scheduledAt);
          final quizRepo = context.read<QuizRepository>();
          await quizRepo.updateQuiz(updatedQuiz);

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Квиз запланирован на ${scheduledAt.day}.${scheduledAt.month}.${scheduledAt.year} в ${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                ),
              ),
            );
          }
        }
      }
=======
    ).then((selectedDate) {
      if (selectedDate == null || !context.mounted) return;

      showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      ).then((selectedTime) {
        if (selectedTime == null || !context.mounted) return;

        final scheduledAt = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        quizRepo.updateQuiz(
          quiz.copyWith(
            scheduledAt: scheduledAt,
            isActive: false,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Квиз запланирован на ${scheduledAt.toString().substring(0, 16)}',
            ),
          ),
        );
      });
>>>>>>> 2e096c9f1c108dfed9888cf4b77d503caf0d5935
    });
  }

  void _exportQuiz(BuildContext context) {
<<<<<<< HEAD
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт квиза'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Выберите формат экспорта:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('GIFT (Moodle)'),
                subtitle: const Text('Формат для импорта в Moodle'),
                onTap: () {
                  final giftContent = ExportService.exportToGiftFormat(quiz);
                  _showExportContent(context, 'quiz_export.gift', giftContent);
                  Navigator.pop(context);
=======
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Экспорт квиза'),
                subtitle: Text('Выберите формат для экспорта'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('GIFT (Moodle)'),
                onTap: () {
                  final content = ExportService.exportToGiftFormat(quiz);
                  Navigator.pop(ctx);
                  _showExportResult(context, 'GIFT', content);
>>>>>>> 2e096c9f1c108dfed9888cf4b77d503caf0d5935
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('CSV'),
<<<<<<< HEAD
                subtitle: const Text('Формат таблицы'),
                onTap: () {
                  final csvContent = ExportService.exportToCsv(quiz);
                  _showExportContent(context, 'quiz_export.csv', csvContent);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_object),
                title: const Text('JSON'),
                subtitle: const Text('Формат данных'),
                onTap: () {
                  final jsonContent = ExportService.exportToJson(quiz);
                  _showExportContent(context, 'quiz_export.json', jsonContent);
                  Navigator.pop(context);
=======
                onTap: () {
                  final content = ExportService.exportToCsv(quiz);
                  Navigator.pop(ctx);
                  _showExportResult(context, 'CSV', content);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('JSON'),
                onTap: () {
                  final content = ExportService.exportToJson(quiz);
                  Navigator.pop(ctx);
                  _showExportResult(context, 'JSON', content);
>>>>>>> 2e096c9f1c108dfed9888cf4b77d503caf0d5935
                },
              ),
            ],
          ),
<<<<<<< HEAD
        ),
      ),
    );
  }

  void _showExportContent(BuildContext context, String filename, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Экспортированный файл: $filename'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              // In a real implementation, this would trigger file download
              // For now, just show a message
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Файл экспортирован (в реальном приложении файл будет скачан)'),
                  ),
                );
              }
            },
            child: const Text('Скачать'),
          ),
        ],
      ),
=======
        );
      },
    );
  }

  void _showExportResult(
    BuildContext context,
    String format,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Экспорт в $format'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(content),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
>>>>>>> 2e096c9f1c108dfed9888cf4b77d503caf0d5935
    );
  }

  void _deleteQuiz(BuildContext context, QuizRepository quizRepo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить квиз?'),
        content: Text('Вы уверены, что хотите удалить квиз "${quiz.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              quizRepo.deleteQuiz(quiz.id);
              Navigator.pop(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Квиз удален')),
                );
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
