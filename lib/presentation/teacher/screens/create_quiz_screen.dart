import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart'; // ← УДАЛИТЬ ЭТОТ ИМПОРТ

import '../../../data/models/quiz_model.dart';

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

  List<Question> _questions = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description;
      _subjectController.text = widget.quiz!.subject;
      _durationController.text = widget.quiz!.duration.toString();
      _questions = widget.quiz!.questions;
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
    if (_formKey.currentState!.validate() && _questions.isNotEmpty) {
      final quiz = Quiz(
        id: widget.quiz?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        subject: _subjectController.text,
        questions: _questions,
        duration: int.parse(_durationController.text),
      );

      Navigator.pop(context, quiz);
    } else if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один вопрос')),
      );
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

  void _addAnswer() {
    setState(() {
      _answers.add(Answer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
        isCorrect: false,
      ));
    });
  }

  void _saveQuestion() {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст вопроса')),
      );
      return;
    }

    final question = Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _questionController.text,
      type: _selectedType,
      answers: _answers.where((a) => a.text.isNotEmpty).toList(),
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
