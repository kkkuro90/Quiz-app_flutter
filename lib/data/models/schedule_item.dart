enum ScheduleItemType {
  quiz,
  task,
  reminder,
  material,
}

class ScheduleItem {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final Duration? duration;
  final ScheduleItemType type;
  final String? relatedQuizId;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.duration,
    this.relatedQuizId,
  });

  bool get isQuiz => type == ScheduleItemType.quiz;
  bool get isTask => type == ScheduleItemType.task;
}

