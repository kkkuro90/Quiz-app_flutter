import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../data/models/quiz_model.dart';
import '../../../data/models/quiz_result_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../core/services/real_time_quiz_service.dart';

class QuizSessionScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizSessionScreen({super.key, required this.quiz});

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, List<String>> _selectedAnswers = {};
  final Map<int, DateTime> _questionStartTimes = {};
  int _remainingTime = 0;
  late Timer _timer;
  late RealTimeQuizService _realTimeService;

  @override
  void initState() {
    super.initState();
    _realTimeService = RealTimeQuizService(); // Keep it in case we need it later
    _remainingTime = widget.quiz.duration * 60;

    // Just use local timer for now, avoid server-side timing issues
    _startLocalTimer();

    // Record start time for the first question
    _recordQuestionStartTime(0);
  }

  /// Start local countdown timer only
  void _startLocalTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  /// Record the start time for a question
  void _recordQuestionStartTime(int questionIndex) {
    _questionStartTimes[questionIndex] = DateTime.now();
  }

  /// Calculate time spent on a question
  Duration? _getTimeSpentOnQuestion(int questionIndex) {
    if (_questionStartTimes.containsKey(questionIndex)) {
      return DateTime.now().difference(_questionStartTimes[questionIndex]!);
    }
    return null;
  }

  @override
  void dispose() {
    _timer.cancel();
    _realTimeService.dispose();

    // Update quiz status when quiz is left
    _realTimeService.updateQuizStatus(
      quizId: widget.quiz.id,
      status: _currentQuestionIndex >= widget.quiz.questions.length - 1 ? 'completed' : 'interrupted',
    );

    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(String answerId) {
    setState(() {
      final currentQuestion = widget.quiz.questions[_currentQuestionIndex];

      if (currentQuestion.type == QuestionType.singleChoice) {
        _selectedAnswers[_currentQuestionIndex] = [answerId];
      } else if (currentQuestion.type == QuestionType.multipleChoice) {
        final currentAnswers = _selectedAnswers[_currentQuestionIndex] ?? [];
        if (currentAnswers.contains(answerId)) {
          currentAnswers.remove(answerId);
        } else {
          currentAnswers.add(answerId);
        }
        _selectedAnswers[_currentQuestionIndex] = currentAnswers;
      }
    });

  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });

      // Record the start time for this question (just moved to)
      _recordQuestionStartTime(_currentQuestionIndex);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });

      // Record the start time for this question (just moved to)
      _recordQuestionStartTime(_currentQuestionIndex);
    }
  }

  void _submitQuiz() async {
    _timer.cancel();

    final quiz = widget.quiz;
    int totalPoints = 0;
    int maxPoints = 0;
    final List<StudentAnswer> answers = [];

    for (int i = 0; i < quiz.questions.length; i++) {
      final question = quiz.questions[i];
      final selected = _selectedAnswers[i] ?? <String>[];
      maxPoints += question.points;

      bool isCorrect = false;
      int points = 0;

      if (question.type == QuestionType.singleChoice) {
        final correctAnswers = question.answers.where((a) => a.isCorrect).toList();
        if (correctAnswers.isNotEmpty && selected.contains(correctAnswers.first.id)) {
          isCorrect = true;
          points = question.points;
          totalPoints += points;
        }
      } else if (question.type == QuestionType.multipleChoice) {
        final correctAnswers = question.answers
            .where((a) => a.isCorrect)
            .map((a) => a.id)
            .toList();
        if (selected.length == correctAnswers.length &&
            selected.every((id) => correctAnswers.contains(id))) {
          isCorrect = true;
          points = question.points;
          totalPoints += points;
        }
      }

      answers.add(
        StudentAnswer(
          questionId: question.id,
          selectedAnswers: List<String>.from(selected),
          textAnswer: null,
          isCorrect: isCorrect,
          points: points,
          timeSpent: null,
        ),
      );
    }

    final percentage = maxPoints > 0 ? totalPoints / maxPoints : 0.0;

    // Сохраняем результат в репозиторий (бэкенд)
    final authRepo = context.read<AuthRepository>();
    final quizRepo = context.read<QuizRepository>();
    final student = authRepo.currentUser;

    if (student != null) {
      final result = QuizResult(
        id: '', // будет проставлен на стороне Firestore
        quizId: quiz.id,
        studentId: student.id,
        studentName: student.name,
        totalPoints: totalPoints,
        maxPoints: maxPoints,
        percentage: percentage,
        completedAt: DateTime.now(),
        answers: answers,
      );

      // Отправляем результат в репозиторий (и далее в Firestore)
      quizRepo.addResult(result);
    }

    // Create and save quiz result
    final result = QuizResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate unique ID
      quizId: widget.quiz.id,
      studentId: 'current_student', // In a real app, this would be the actual student ID
      studentName: 'Current Student', // In a real app, this would be the actual student name
      totalPoints: totalPoints,
      maxPoints: maxPoints,
      percentage: percentage,
      completedAt: DateTime.now(),
      answers: answers,
    );

    // Save result to repository (which also saves to Firestore)
    quizRepo.addResult(result);

    // Skip updating server status to avoid permission issues

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizResultDialog(
        totalPoints: totalPoints,
        maxPoints: maxPoints,
        percentage: percentage,
        onClose: () {
          if (context.mounted) {
            Navigator.pop(context); // Simply pop the QuizSessionScreen
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.quiz.questions[_currentQuestionIndex];
    final selectedAnswers = _selectedAnswers[_currentQuestionIndex] ?? [];
    String? selectedSingleAnswer; // ← ДОБАВЛЕНО для RadioGroup

    // Check if this is the first time viewing this question
    if (!_questionStartTimes.containsKey(_currentQuestionIndex)) {
      _recordQuestionStartTime(_currentQuestionIndex);
    }

    if (currentQuestion.type == QuestionType.singleChoice &&
        selectedAnswers.isNotEmpty) {
      selectedSingleAnswer = selectedAnswers.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _remainingTime < 60 ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatTime(_remainingTime),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            ),
            const SizedBox(height: 16),
            Text(
              'Вопрос ${_currentQuestionIndex + 1} из ${widget.quiz.questions.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentQuestion.text,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    if (currentQuestion.type == QuestionType.singleChoice) ...[
                      // НОВЫЙ СПОСОБ для single choice с RadioGroup
                      ...currentQuestion.answers.map((answer) {
                        return _buildRadioAnswerOption(
                            answer, selectedSingleAnswer == answer.id);
                      }),
                    ] else if (currentQuestion.type ==
                        QuestionType.multipleChoice) ...[
                      // Старый способ для multiple choice
                      ...currentQuestion.answers.map((answer) {
                        return _buildCheckboxAnswerOption(
                            answer, selectedAnswers.contains(answer.id));
                      }),
                    ] else ...[
                      // Текстовый ответ
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Ваш ответ',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    child: const Text('Назад'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentQuestionIndex ==
                            widget.quiz.questions.length - 1
                        ? _submitQuiz
                        : _nextQuestion,
                    child: Text(
                      _currentQuestionIndex == widget.quiz.questions.length - 1
                          ? 'Завершить'
                          : 'Далее',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // НОВЫЙ МЕТОД для Radio (single choice)
  Widget _buildRadioAnswerOption(Answer answer, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        title: Text(answer.text),
        leading: Radio<String>(
          value: answer.id,
          // ignore: deprecated_member_use
          groupValue: isSelected ? answer.id : null,
          // ignore: deprecated_member_use
          onChanged: (value) => _selectAnswer(answer.id),
        ),
        onTap: () => _selectAnswer(answer.id),
      ),
    );
  }

  // НОВЫЙ МЕТОД для Checkbox (multiple choice)
  Widget _buildCheckboxAnswerOption(Answer answer, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        title: Text(answer.text),
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) => _selectAnswer(answer.id),
        ),
        onTap: () => _selectAnswer(answer.id),
      ),
    );
  }
}

class QuizResultDialog extends StatelessWidget {
  final int totalPoints;
  final int maxPoints;
  final double percentage;
  final VoidCallback onClose;

  const QuizResultDialog({
    super.key,
    required this.totalPoints,
    required this.maxPoints,
    required this.percentage,
    required this.onClose,
  });

  String get grade {
    if (percentage >= 0.85) return '5';
    if (percentage >= 0.70) return '4';
    if (percentage >= 0.50) return '3';
    return '2';
  }

  Color get gradeColor {
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Результат теста'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: gradeColor,
            child: Text(
              grade,
              style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('$totalPoints/$maxPoints баллов'),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage.toDouble(), // ← ИСПРАВЛЕНО: явное преобразование
            backgroundColor: Colors.grey[300],
            color: gradeColor,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text('Завершить'),
        ),
      ],
    );
  }
}
