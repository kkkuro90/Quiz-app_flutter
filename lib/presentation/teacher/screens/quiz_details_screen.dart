import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/export_service.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/quiz_repository.dart';

class QuizDetailsScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizDetailsScreen({super.key, required this.quiz});

  @override
  State<QuizDetailsScreen> createState() => _QuizDetailsScreenState();
}

class _QuizDetailsScreenState extends State<QuizDetailsScreen> {
  late Quiz _quiz;
  bool _isEditing = false;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _subjectController;
  late final TextEditingController _durationController;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _quiz = widget.quiz;
    _titleController = TextEditingController(text: _quiz.title);
    _descriptionController = TextEditingController(text: _quiz.description);
    _subjectController = TextEditingController(text: _quiz.subject);
    _durationController =
        TextEditingController(text: _quiz.duration.toString());
    _scheduledAt = _quiz.scheduledAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizRepo = context.watch<QuizRepository>();
    final formatter = DateFormat('dd.MM.yyyy HH:mm');

    // Получаем актуальное состояние квиза из репозитория
    Quiz? currentQuiz;
    try {
      currentQuiz = quizRepo.quizzes.firstWhere(
        (q) => q.id == _quiz.id,
      );
    } catch (e) {
      currentQuiz = _quiz;
    }

    final startAt = _scheduledAt;
    final endAt = startAt != null
        ? startAt.add(
            Duration(
              minutes:
                  int.tryParse(_durationController.text) ?? _quiz.duration,
            ),
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Квиз'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showExportMenu(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Редактирование' : 'Информация о квизе',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () async {
                    if (_isEditing) {
                      final updated = _quiz.copyWith(
                        title: _titleController.text,
                        description: _descriptionController.text,
                        subject: _subjectController.text,
                        duration: int.tryParse(_durationController.text) ??
                            _quiz.duration,
                        scheduledAt: _scheduledAt,
                      );
                      await quizRepo.updateQuiz(updated);
                      if (mounted) {
                        setState(() {
                          _quiz = updated;
                          _isEditing = false;
                        });
                      }
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                  child: Text(_isEditing ? 'Сохранить' : 'Редактировать'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              label: 'Название',
              controller: _titleController,
              editable: _isEditing,
            ),
            const SizedBox(height: 12),
            _buildField(
              context,
              label: 'Описание',
              controller: _descriptionController,
              editable: _isEditing,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildField(
              context,
              label: 'Предмет',
              controller: _subjectController,
              editable: _isEditing,
            ),
            const SizedBox(height: 12),
            _buildField(
              context,
              label: 'Длительность (мин)',
              controller: _durationController,
              editable: _isEditing,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Время начала квиза'),
              subtitle: Text(
                startAt != null
                    ? formatter.format(startAt)
                    : 'Не запланирован',
              ),
              trailing: _isEditing
                  ? TextButton(
                      onPressed: _pickStartDateTime,
                      child: Text(startAt != null ? 'Изменить' : 'Выбрать'),
                    )
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.stop_circle_outlined),
              title: const Text('Время окончания'),
              subtitle: Text(
                endAt != null
                    ? formatter.format(endAt)
                    : 'Будет рассчитано после планирования',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Количество вопросов'),
              subtitle: Text('${_quiz.questions.length} вопросов'),
            ),
            const SizedBox(height: 24),
            if (currentQuiz != null) ...[
              currentQuiz.isActive
                  ? ElevatedButton.icon(
                      onPressed: () async {
                        final updatedQuiz = currentQuiz!.copyWith(isActive: false);
                        await quizRepo.updateQuiz(updatedQuiz);
                        if (mounted) {
                          setState(() {
                            _quiz = updatedQuiz;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Квиз остановлен'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.stop),
                      label: const Text('Остановить квиз'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () async {
                        final updatedQuiz = currentQuiz!.copyWith(isActive: true);
                        await quizRepo.updateQuiz(updatedQuiz);
                        if (mounted) {
                          setState(() {
                            _quiz = updatedQuiz;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Квиз запущен!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Запустить квиз'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool editable,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    if (!editable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            controller.text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      );
    }

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final initialDate = _scheduledAt ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );

    if (pickedTime == null) return;

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _showExportMenu(BuildContext context) {
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
                  final content = ExportService.exportToGiftFormat(_quiz);
                  Navigator.pop(ctx);
                  _showExportResult(context, 'GIFT', content);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('CSV'),
                onTap: () {
                  final content = ExportService.exportToCsv(_quiz);
                  Navigator.pop(ctx);
                  _showExportResult(context, 'CSV', content);
                },
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('JSON'),
                onTap: () {
                  final content = ExportService.exportToJson(_quiz);
                  Navigator.pop(ctx);
                  _showExportResult(context, 'JSON', content);
                },
              ),
            ],
          ),
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
    );
  }
}


