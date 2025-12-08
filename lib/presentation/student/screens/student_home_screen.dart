import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/models/quiz_model.dart';
import '../../shared/widgets/quiz_card.dart';
import 'join_quiz_screen.dart';
import 'quiz_catalog_screen.dart';
import 'quiz_session_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizRepo = context.watch<QuizRepository>();
    final activeQuizzes = quizRepo.quizzes.where((q) => q.isActive).toList();
    final availableQuizzes = quizRepo.quizzes.where((q) => !q.isActive).take(3).toList();

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinQuizScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.pin),
                label: const Text('🎯 Присоединиться к квизу по PIN'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizCatalogScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.book),
                label: const Text('📚 Самостоятельное обучение'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (quizRepo.quizzes.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Предметы',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quizRepo.quizzes
                    .map((q) => q.subject)
                    .toSet()
                    .map(
                      (subject) => ActionChip(
                        label: Text(subject),
                        avatar: const Icon(Icons.book),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizCatalogScreen(
                                initialSubject: subject,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            if (availableQuizzes.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Рекомендуемые тесты',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...availableQuizzes.map((quiz) {
                final progress = 0.0; // TODO: Получить из локального хранилища
                return QuizCard(
                  title: quiz.title,
                  subtitle: '${quiz.questions.length} вопросов • ${progress > 0 ? '${(progress * 100).toStringAsFixed(0)}% завершено' : 'Не начат'}',
                  trailing: progress > 0
                      ? SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.borderColor,
                            color: AppColors.secondary,
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizSessionScreen(quiz: quiz),
                      ),
                    );
                  },
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
