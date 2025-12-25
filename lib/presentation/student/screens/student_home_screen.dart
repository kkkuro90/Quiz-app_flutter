import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/models/quiz_result_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../shared/widgets/quiz_card.dart';
import 'join_quiz_screen.dart';
import 'quiz_catalog_screen.dart';
import 'quiz_session_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizRepo = context.watch<QuizRepository>();
    final authRepo = context.watch<AuthRepository>();
    final student = authRepo.currentUser;

    final Future<List<QuizResult>> resultsFuture = student != null
        ? quizRepo.getStudentResultsWithSort(student.id)
        : Future.value(<QuizResult>[]);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: FutureBuilder<List<QuizResult>>(
          future: resultsFuture,
          builder: (context, snapshot) {
            final results = snapshot.data ?? [];
            final passedQuizIds =
                results.map((r) => r.quizId).toSet();

            final activeQuizzes =
                quizRepo.quizzes.where((q) => q.isActive).toList();

<<<<<<< HEAD
            // Ближайшие тесты: показываем только тесты на оценку по времени, которые скоро откроются
            final now = DateTime.now();
            final upcomingQuizzes = quizRepo.quizzes
                .where((q) {
                  if (passedQuizIds.contains(q.id)) return false;
                  // Показываем только тесты на оценку по времени
                  if (q.quizType != QuizType.timedTest) return false;
                  if (q.scheduledAt == null) return false;
                  // Показываем только тесты, которые еще не закончились
                  final start = q.scheduledAt!;
                  final end = start.add(Duration(minutes: q.duration));
                  // Показываем тесты, которые еще не закончились
                  return now.isBefore(end);
                })
                .toList()
              ..sort((a, b) {
                // Сортируем по времени начала (ближайшие первыми)
                final aStart = a.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final bStart = b.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return aStart.compareTo(bStart);
              });
            
            final availableQuizzes = upcomingQuizzes.take(3).toList();
=======
            // Фильтруем тесты: исключаем пройденные
            // Показываем все тесты с scheduledAt (даже если время ещё не наступило),
            // а доступность по времени проверяем уже при нажатии.
            final availableQuizzes = quizRepo.quizzes
                .where((q) {
                  if (passedQuizIds.contains(q.id)) return false;
                  return q.scheduledAt != null;
                })
                .take(3)
                .toList();
>>>>>>> 2e096c9f1c108dfed9888cf4b77d503caf0d5935

            return ListView(
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
<<<<<<< HEAD
                // Предметы только для тестов самостоятельного обучения
                Builder(
                  builder: (context) {
                    final selfStudySubjects = quizRepo.quizzes
                        .where((q) => q.quizType == QuizType.selfStudy)
                        .map((q) => q.subject.trim())
                        .where((subject) => subject.isNotEmpty)
                        .toSet()
                        .toList()
                      ..sort();
                    
                    if (selfStudySubjects.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Предметы',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selfStudySubjects
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
                    );
                  },
                ),
                if (results.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Пройденные тесты',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...results.map((result) {
                    Quiz? quiz;
                    for (final q in quizRepo.quizzes) {
                      if (q.id == result.quizId) {
                        quiz = q;
                        break;
                      }
                    }
                    if (quiz == null) {
                      return const SizedBox.shrink();
                    }

                    final correctCount =
                        result.answers.where((a) => a.isCorrect).length;
                    final totalAnswers = result.answers.length;

                    return QuizCard(
                      title: quiz.title,
                      subtitle:
                          '$correctCount/$totalAnswers правильных ответов • ${(result.percentage * 100).toStringAsFixed(0)}%',
                      trailing: Chip(
                        label: Text('Оценка ${result.grade}'),
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Тест уже пройден, повторное прохождение недоступно'),
                          ),
                        );
                      },
                    );
=======
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
                if (results.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Пройденные тесты',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...results.map((result) {
                    Quiz? quiz;
                    for (final q in quizRepo.quizzes) {
                      if (q.id == result.quizId) {
                        quiz = q;
                        break;
                      }
                    }
                    if (quiz == null) {
                      return const SizedBox.shrink();
                    }

                    final correctCount =
                        result.answers.where((a) => a.isCorrect).length;
                    final totalAnswers = result.answers.length;

                    return QuizCard(
                      title: quiz.title,
                      subtitle:
                          '$correctCount/$totalAnswers правильных ответов • ${(result.percentage * 100).toStringAsFixed(0)}%',
                      trailing: Chip(
                        label: Text('Оценка ${result.grade}'),
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Тест уже пройден, повторное прохождение недоступно'),
                          ),
                        );
                      },
                    );
>>>>>>> 2e096c9f1c108dfed9888cf4b77d503caf0d5935
                  }),
                ],
                if (availableQuizzes.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
<<<<<<< HEAD
                    'Ближайшие тесты',
=======
                    'Рекомендуемые тесты',
>>>>>>> 2e096c9f1c108dfed9888cf4b77d503caf0d5935
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                   ...availableQuizzes.map((quiz) {
                     // Окно доступности по времени
                     final now = DateTime.now();
                     final start = quiz.scheduledAt!;
                     final end =
                         start.add(Duration(minutes: quiz.duration));
                     final isOpen = now.isAfter(
                           start.subtract(const Duration(seconds: 1)),
                         ) &&
                         now.isBefore(end);

                     // Текст статуса для ученика
                     String statusText;
                     if (!isOpen) {
                       if (now.isBefore(start)) {
                         statusText =
                             'Начнётся: ${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                       } else {
                         statusText = 'Тест завершён';
                       }
                     } else {
                       statusText = 'Доступен сейчас';
                     }

                     return QuizCard(
                       title: quiz.title,
                       subtitle:
                           '${quiz.questions.length} вопросов • $statusText',
                       onTap: () async {
                         if (student != null) {
                           final results =
                               await quizRepo.getStudentResultsWithSort(
                             student.id,
                           );
                           final alreadyPassed =
                               results.any((r) => r.quizId == quiz.id);
                           if (alreadyPassed) {
                             if (context.mounted) {
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

                         // Проверяем окно доступности по времени
                         if (!isOpen) {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text(
                                   now.isBefore(start)
                                       ? 'Тест будет доступен с ${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'
                                       : 'Тест уже завершён',
                                 ),
                               ),
                             );
                           }
                           return;
                         }

                         if (context.mounted) {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) =>
                                   QuizSessionScreen(quiz: quiz),
                             ),
                           );
                         }
                       },
                     );
                   }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
