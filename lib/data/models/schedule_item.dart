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
  final String? teacherId; // Добавляем teacherId для индекса
  final DateTime? createdAt; // Дополнительное поле

  ScheduleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.duration,
    this.relatedQuizId,
    this.teacherId,
    this.createdAt,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      duration: json['durationMinutes'] != null
          ? Duration(minutes: json['durationMinutes'])
          : null,
      type: ScheduleItemType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'task'),
        orElse: () => ScheduleItemType.task,
      ),
      relatedQuizId: json['relatedQuizId'],
      teacherId: json['teacherId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      if (duration != null) 'durationMinutes': duration!.inMinutes,
      'type': type.name,
      if (relatedQuizId != null) 'relatedQuizId': relatedQuizId,
      if (teacherId != null) 'teacherId': teacherId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  bool get isQuiz => type == ScheduleItemType.quiz;
  bool get isTask => type == ScheduleItemType.task;
}

