enum NotificationType {
  quiz,
  reminder,
  material,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;
  final String? userId; // Для индекса в Firestore

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.userId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
      type: NotificationType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'system'),
        orElse: () => NotificationType.system,
      ),
      isRead: json['isRead'] ?? false,
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
      if (userId != null) 'userId': userId,
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      type: type,
      isRead: isRead ?? this.isRead,
      userId: userId,
    );
  }
}

