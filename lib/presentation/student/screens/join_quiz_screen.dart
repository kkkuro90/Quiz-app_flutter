import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/repositories/quiz_repository.dart';
import 'quiz_session_screen.dart';

class JoinQuizScreen extends StatefulWidget {
  const JoinQuizScreen({super.key});

  @override
  State<JoinQuizScreen> createState() => _JoinQuizScreenState();
}

class _JoinQuizScreenState extends State<JoinQuizScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinQuiz() async {
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректный 4-значный PIN-код')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Поиск активного квиза по PIN-коду
    final quizRepo = context.read<QuizRepository>();
    final authRepo = context.read<AuthRepository>();
    final student = authRepo.currentUser;

    final activeQuiz = quizRepo.quizzes.firstWhere(
      (quiz) {
        final pin = quiz.pinCode ?? _getQuizPin(quiz);
        return quiz.isActive && pin == _pinController.text;
      },
      orElse: () => Quiz(
        id: '',
        title: '',
        description: '',
        subject: '',
        questions: [],
      ),
    );

    if (activeQuiz.id.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Квиз с таким PIN-кодом не найден')),
        );
      }
      return;
    }

    // Проверяем, проходил ли студент этот квиз ранее
    if (student != null) {
      final results = await quizRepo.getStudentResultsWithSort(student.id);
      final alreadyPassed = results.any((r) => r.quizId == activeQuiz.id);
      if (alreadyPassed) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Вы уже проходили этот тест, повторное прохождение недоступно',
              ),
            ),
          );
        }
        return;
      }
    }

    // Блокировка по времени: тест доступен только если:
    // 1. Квиз активен И имеет PIN-код
    // 2. Если квиз запланирован (scheduledAt), то текущее время должно быть в интервале [start, end]
    // 3. Если квиз не запланирован, но активен и имеет PIN - доступен сразу
    final now = DateTime.now();
    final start = activeQuiz.scheduledAt;
    bool isOpen = false;

    if (start != null) {
      // Квиз запланирован - проверяем время
      final end = start.add(Duration(minutes: activeQuiz.duration));
      isOpen = now.isAfter(start.subtract(const Duration(seconds: 1))) &&
          now.isBefore(end);
    } else {
      // Квиз не запланирован - доступен если активен и имеет PIN
      isOpen = activeQuiz.isActive && activeQuiz.pinCode != null;
    }

    if (!isOpen) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              start != null
                  ? 'Тест будет доступен с ${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'
                  : 'Тест сейчас недоступен. Убедитесь, что квиз активирован.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizSessionScreen(quiz: activeQuiz),
        ),
      );
    }
  }

  String _getQuizPin(Quiz quiz) {
    // Simple hash-based PIN generation for quizzes without a stored PIN
    return (quiz.hashCode.abs() % 10000).toString().padLeft(4, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Присоединение к квизу'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pin,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Введите PIN-код',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _pinController,
                        decoration: const InputDecoration(
                          labelText: 'PIN-код',
                          hintText: '0000',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _joinQuiz,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Присоединиться'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('← Назад'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
