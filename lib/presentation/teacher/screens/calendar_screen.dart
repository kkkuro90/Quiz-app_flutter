import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/quiz_repository.dart';
import '../../../data/models/quiz_model.dart';
import '../../../data/models/schedule_item.dart';
import '../controllers/teacher_dashboard_controller.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final quizRepo = context.watch<QuizRepository>();
    final dashboard = context.watch<TeacherDashboardController>();
    final scheduleItems = dashboard.schedule;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь квизов'),
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildCalendarGrid(scheduleItems),
          const SizedBox(height: 16),
          _buildScheduledItems(
            scheduleItems,
            quizRepo,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedDate =
                      DateTime(_selectedDate.year, _selectedDate.month - 1);
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedDate =
                      DateTime(_selectedDate.year, _selectedDate.month + 1);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(List<ScheduleItem> scheduleItems) {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.2,
        ),
        itemCount: daysInMonth + firstWeekday - 1,
        itemBuilder: (context, index) {
          if (index < firstWeekday - 1) {
            return const SizedBox.shrink();
          }

          final day = index - firstWeekday + 2;
          final currentDate =
              DateTime(_selectedDate.year, _selectedDate.month, day);
          final isToday = _isSameDay(currentDate, DateTime.now());
          final hasItems = scheduleItems.any(
            (item) => _isSameDay(item.date, currentDate),
          );

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = currentDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isToday ? Colors.blue : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isSameDay(currentDate, _selectedDate)
                      ? Colors.blue
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasItems) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduledItems(
    List<ScheduleItem> scheduleItems,
    QuizRepository quizRepo,
  ) {
    final itemsForDate = scheduleItems.where(
      (item) => _isSameDay(item.date, _selectedDate),
    );

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'План на ${DateFormat('dd.MM.yyyy').format(_selectedDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            itemsForDate.isEmpty
                ? const Expanded(
                    child: Center(
                      child: Text(
                        'Нет планов на выбранную дату',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView(
                      children: itemsForDate.map(
                        (item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              item.isQuiz ? Icons.quiz : Icons.event_note,
                              color: item.isQuiz ? Colors.blue : Colors.orange,
                            ),
                            title: Text(item.title),
                            subtitle: _buildItemSubtitle(item, quizRepo),
                            trailing: Text(DateFormat('HH:mm').format(item.date)),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSubtitle(ScheduleItem item, QuizRepository quizRepo) {
    if (item.isQuiz && item.relatedQuizId != null) {
      final quiz = quizRepo.quizzes.firstWhere(
        (quiz) => quiz.id == item.relatedQuizId,
        orElse: () => Quiz(
          id: 'unknown',
          title: 'Unknown Quiz',
          description: 'Quiz not found',
          subject: 'Unknown',
          questions: [],
        ),
      );
      return Text(
        '${quiz.questions.length} вопросов • ${quiz.duration} мин',
      );
    }

    return Text(item.description);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

}
