import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/quiz_model.dart'; // QuizType
import '../../../data/repositories/quiz_repository.dart';
import '../../shared/widgets/quiz_card.dart';
import 'quiz_session_screen.dart';

class QuizCatalogScreen extends StatefulWidget {
  final String? initialSubject;

  const QuizCatalogScreen({super.key, this.initialSubject});

  @override
  State<QuizCatalogScreen> createState() => _QuizCatalogScreenState();
}

class _QuizCatalogScreenState extends State<QuizCatalogScreen> {
  String _selectedSubject = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    final quizRepo = context.watch<QuizRepository>();
    
    // Получаем список всех предметов только для тестов самостоятельного обучения (убираем дубликаты и пробелы)
    final subjects = quizRepo.quizzes
        .where((q) => q.quizType == QuizType.selfStudy)
        .map((q) => q.subject.trim())
        .where((subject) => subject.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final now = DateTime.now();
    
    // Фильтрация квизов для самостоятельного обучения
    // Показываем только тесты типа selfStudy (самостоятельное обучение)
    // Исключаем тесты, которые закрыты по дедлайну
    var filteredQuizzes = quizRepo.quizzes.where((quiz) {
      final matchesSubject = _selectedSubject == 'all' || quiz.subject.trim() == _selectedSubject;
      final matchesSearch = _searchQuery.isEmpty ||
          quiz.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          quiz.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Показываем только тесты для самостоятельного обучения
      if (quiz.quizType != QuizType.selfStudy) return false;
      
      // Если тест запланирован (что не должно быть для selfStudy, но на всякий случай),
      // проверяем, что он еще не закрыт по дедлайну
      if (quiz.scheduledAt != null) {
        final start = quiz.scheduledAt!;
        final end = start.add(Duration(minutes: quiz.duration));
        // Если тест уже закончился, не показываем его
        if (now.isAfter(end)) return false;
      }
      
      return matchesSubject && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог тестов'),
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Поиск
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск тестов...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Фильтр по предметам
            if (subjects.isNotEmpty)
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('all', 'Все'),
                    const SizedBox(width: 8),
                    ...subjects.map((subject) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(subject, subject),
                        )),
                  ],
                ),
              ),
            // Список тестов
            Expanded(
              child: filteredQuizzes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Тесты не найдены',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredQuizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = filteredQuizzes[index];
                        return QuizCard(
                          title: quiz.title,
                          subtitle: '${quiz.subject} • ${quiz.questions.length} вопросов • ${quiz.duration} мин',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizSessionScreen(quiz: quiz),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedSubject == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSubject = value;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }
}

