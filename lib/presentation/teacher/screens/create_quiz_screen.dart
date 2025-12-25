import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/auth_repository.dart';

class CreateQuizScreen extends StatefulWidget {
  final Quiz? quiz;

  const CreateQuizScreen({super.key, this.quiz});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _pinController = TextEditingController();

  List<Question> _questions = [];
  bool _isGenerating = false;
  DateTime? _scheduledAt;
  QuizType _quizType = QuizType.timedTest; // По умолчанию тест на оценку

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description;
      _subjectController.text = widget.quiz!.subject;
      _durationController.text = widget.quiz!.duration.toString();
      _pinController.text = widget.quiz!.pinCode ?? '';
      _questions = List.from(widget.quiz!.questions);
      _scheduledAt = widget.quiz!.scheduledAt;
      _quizType = widget.quiz!.quizType;
    }
  }

  Future<void> _pickFile() async {
    // Временная заглушка вместо file_picker
    setState(() {
      _isGenerating = true;
    });

    // Имитация выбора файла и генерации вопросов
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _questions.addAll([
        Question(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Сгенерированный вопрос из файла (демо)',
          type: QuestionType.singleChoice,
          answers: [
            Answer(id: '1', text: 'Правильный ответ', isCorrect: true),
            Answer(id: '2', text: 'Неправильный ответ 1', isCorrect: false),
            Answer(id: '3', text: 'Неправильный ответ 2', isCorrect: false),
          ],
        ),
      ]);
      _isGenerating = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вопросы сгенерированы успешно! (демо)')),
      );
    }
  }

  /*
  Future<void> _generateQuestionsFromFile() async {
    // Упрощенная версия без file_picker
    setState(() {
      _isGenerating = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _questions.addAll([
        Question(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Демонстрационный вопрос из файла',
          type: QuestionType.singleChoice,
          answers: [
            Answer(id: '1', text: 'Правильный ответ', isCorrect: true),
            Answer(id: '2', text: 'Неправильный ответ 1', isCorrect: false),
            Answer(id: '3', text: 'Неправильный ответ 2', isCorrect: false),
          ],
        ),
      ]);
      _isGenerating = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вопросы сгенерированы успешно!')),
      );
    }
  }
    */
  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => AddQuestionDialog(
        onQuestionAdded: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  void _saveQuiz() {
    if (!mounted) return;
    
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все обязательные поля')),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один вопрос')),
      );
      return;
    }

    try {
      final ownerId =
          context.read<AuthRepository>().currentUser?.id ?? 'unknown-teacher';

      final duration = int.tryParse(_durationController.text) ?? 30;
      
      // Для самостоятельного обучения не требуется время начала и PIN-код
      final pinCode = _quizType == QuizType.timedTest && _pinController.text.trim().isNotEmpty
          ? _pinController.text.trim()
          : null;
      final scheduledAt = _quizType == QuizType.timedTest ? _scheduledAt : null;
      final isActive = _quizType == QuizType.timedTest ? false : false; // Самостоятельное обучение не активируется
      
      final quiz = widget.quiz != null
          ? widget.quiz!.copyWith(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              subject: _subjectController.text.trim(),
              questions: _questions,
              duration: duration,
              pinCode: pinCode,
              scheduledAt: scheduledAt,
              quizType: _quizType,
              isActive: isActive,
            )
          : Quiz(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              subject: _subjectController.text.trim(),
              questions: _questions,
              duration: duration,
              pinCode: pinCode,
              scheduledAt: scheduledAt,
              ownerId: ownerId,
              quizType: _quizType,
              isActive: isActive,
            );

      if (mounted) {
        Navigator.pop(context, quiz);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.quiz == null ? 'Создать квиз' : 'Редактировать квиз'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuiz,
          ),
        ],
      ),
      body: _isGenerating
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Название квиза',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Предмет',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Длительность (мин)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Выбор типа квиза
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Тип квиза',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            RadioListTile<QuizType>(
                              title: const Text('Тест на оценку по времени'),
                              subtitle: const Text('Тест с ограничением по времени, доступен в определенное время'),
                              value: QuizType.timedTest,
                              groupValue: _quizType,
                              onChanged: (value) {
                                setState(() {
                                  _quizType = value!;
                                });
                              },
                            ),
                            RadioListTile<QuizType>(
                              title: const Text('Самостоятельное обучение'),
                              subtitle: const Text('Всегда доступен для прохождения, без ограничений по времени'),
                              value: QuizType.selfStudy,
                              groupValue: _quizType,
                              onChanged: (value) {
                                setState(() {
                                  _quizType = value!;
                                  // Для самостоятельного обучения убираем время начала
                                  if (value == QuizType.selfStudy) {
                                    _scheduledAt = null;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Время начала квиза (только для тестов на оценку)
                    if (_quizType == QuizType.timedTest) ...[
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: const Text('Время начала квиза'),
                        subtitle: Text(
                          _scheduledAt != null
                              ? '${_formatDate(_scheduledAt!)} • ${_formatTime(_scheduledAt!)}'
                              : 'Не выбрано',
                        ),
                        trailing: TextButton(
                          onPressed: _pickStartDateTime,
                          child: Text(
                            _scheduledAt != null ? 'Изменить' : 'Выбрать',
                          ),
                        ),
                      ),
                    ],
                    // PIN-код только для тестов на оценку
                    if (_quizType == QuizType.timedTest) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pinController,
                        decoration: const InputDecoration(
                          labelText: 'PIN-код (для подключения учеников)',
                          hintText: 'Введите 4-значный PIN',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        enabled: widget.quiz?.isActive != true, // Disable if quiz is already active
                      ),
                    ],
                    if (widget.quiz?.pinCode != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.info, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'PIN: ${widget.quiz!.pinCode}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            if (widget.quiz?.pinExpiresAt != null)
                              Text(
                                'Срок действия: ${widget.quiz!.pinExpiresAt!.toString().substring(0, 16)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Загрузка из файла',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Поддерживаемые форматы: PDF, DOCX, TXT, GIFT (демо-версия)',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Демо: Загрузить файл'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _addQuestion,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Добавить вопрос'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Вопросы (${_questions.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ..._questions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(question.text),
                          subtitle: Text(
                            'Тип: ${_getQuestionTypeText(question.type)} • Баллов: ${question.points}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _questions.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  String _getQuestionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.singleChoice:
        return 'Один вариант';
      case QuestionType.multipleChoice:
        return 'Несколько вариантов';
      case QuestionType.textAnswer:
        return 'Текстовый ответ';
    }
  }

  Future<void> _pickStartDateTime() async {
    if (!mounted) return;
    
    final now = DateTime.now();
    final initialDate = _scheduledAt ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );

    if (pickedTime == null) return;
    if (!mounted) return;

    final newScheduledAt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (mounted) {
      setState(() {
        _scheduledAt = newScheduledAt;
      });
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class AddQuestionDialog extends StatefulWidget {
  final Function(Question) onQuestionAdded;

  const AddQuestionDialog({super.key, required this.onQuestionAdded});

  @override
  State<AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _questionController = TextEditingController();
  QuestionType _selectedType = QuestionType.singleChoice;
  final List<Answer> _answers = [
    Answer(id: '1', text: '', isCorrect: true),
    Answer(id: '2', text: '', isCorrect: false),
  ];
  final List<TextEditingController> _textAnswerControllers = [
    TextEditingController(),
  ];

  void _addAnswer() {
    setState(() {
      _answers.add(Answer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
        isCorrect: false,
      ));
    });
  }

  void _addTextAnswer() {
    setState(() {
      _textAnswerControllers.add(TextEditingController());
    });
  }

  void _removeTextAnswer(int index) {
    if (_textAnswerControllers.length > 1) {
      setState(() {
        _textAnswerControllers[index].dispose();
        _textAnswerControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _textAnswerControllers) {
      controller.dispose();
    }
    _questionController.dispose();
    super.dispose();
  }

  void _saveQuestion() {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст вопроса')),
      );
      return;
    }

    List<String>? correctTextAnswers;
    if (_selectedType == QuestionType.textAnswer) {
      correctTextAnswers = _textAnswerControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (correctTextAnswers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Добавьте хотя бы один правильный вариант ответа')),
        );
        return;
      }
    }

    final question = Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _questionController.text,
      type: _selectedType,
      answers: _answers.where((a) => a.text.isNotEmpty).toList(),
      correctTextAnswers: correctTextAnswers,
    );

    widget.onQuestionAdded(question);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить вопрос'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Текст вопроса',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<QuestionType>(
              initialValue: _selectedType,
              items: QuestionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getQuestionTypeText(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Тип вопроса',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Показываем поля для правильных текстовых ответов только для текстовых вопросов
            if (_selectedType == QuestionType.textAnswer) ...[
              const Text(
                'Правильные варианты ответов:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._textAnswerControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Правильный ответ ${index + 1}',
                          border: const OutlineInputBorder(),
                          hintText: 'Введите правильный вариант ответа',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _textAnswerControllers.length > 1
                          ? () => _removeTextAnswer(index)
                          : null,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addTextAnswer,
                icon: const Icon(Icons.add),
                label: const Text('Добавить вариант ответа'),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Показываем варианты ответов для single/multiple choice
              ..._answers.asMap().entries.map((entry) {
              final index = entry.key;
              final answer = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: answer.text,
                      decoration: InputDecoration(
                        labelText: 'Вариант ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _answers[index] = Answer(
                          id: answer.id,
                          text: value,
                          isCorrect: answer.isCorrect,
                        );
                      },
                    ),
                  ),
                  Checkbox(
                    value: answer.isCorrect,
                    onChanged: _selectedType == QuestionType.multipleChoice
                        ? (value) {
                            setState(() {
                              _answers[index] = Answer(
                                id: answer.id,
                                text: answer.text,
                                isCorrect: value ?? false,
                              );
                            });
                          }
                        : (value) {
                            // Для single choice снимаем выделение с других
                            setState(() {
                              for (int i = 0; i < _answers.length; i++) {
                                _answers[i] = Answer(
                                  id: _answers[i].id,
                                  text: _answers[i].text,
                                  isCorrect: i == index,
                                );
                              }
                            });
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _answers.length > 2
                        ? () {
                            setState(() {
                              _answers.removeAt(index);
                            });
                          }
                        : null,
                  ),
                ],
              );
              }),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addAnswer,
                icon: const Icon(Icons.add),
                label: const Text('Добавить вариант'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveQuestion,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  String _getQuestionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.singleChoice:
        return 'Один правильный ответ';
      case QuestionType.multipleChoice:
        return 'Несколько правильных ответов';
      case QuestionType.textAnswer:
        return 'Текстовый ответ';
    }
  }
}
