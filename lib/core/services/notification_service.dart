import '../../data/models/app_notification_model.dart';
import '../../data/models/quiz_model.dart';

class NotificationService {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications..sort(_sortByDateDesc));

  void seed(List<AppNotification> notifications) {
    _notifications
      ..clear()
      ..addAll(notifications);
  }

  void publishQuizAnnouncement(Quiz quiz, String userId) {
    final message =
        'Новый тест "${quiz.title}" назначен на ${quiz.scheduledAt != null ? _formatDate(quiz.scheduledAt!) : 'ближайшее время'}';
    addNotification(
      AppNotification(
        id: 'notify-${quiz.id}',
        title: 'Запланирован новый тест',
        message: message,
        createdAt: DateTime.now(),
        type: NotificationType.quiz,
        userId: userId,
      ),
    );
  }

  void addNotification(AppNotification notification) {
    _notifications.removeWhere((item) => item.id == notification.id);
    _notifications.add(notification);
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  static int _sortByDateDesc(
    AppNotification a,
    AppNotification b,
  ) =>
      b.createdAt.compareTo(a.createdAt);

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
