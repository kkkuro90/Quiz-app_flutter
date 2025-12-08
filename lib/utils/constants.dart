class AppConstants {
  static const String appName = 'Quiz PWA';
  static const String appDescription = 'Интерактивные квизы с оффлайн-режимом';

  static const List<Map<String, dynamic>> quickQuizzes = [
    {
      'id': 'math',
      'title': 'Математика',
      'icon': '➗',
      'testCount': 15,
      'color': 0xFF4361EE,
    },
    {
      'id': 'history',
      'title': 'История',
      'icon': '🏛️',
      'testCount': 12,
      'color': 0xFF3A0CA3,
    },
    {
      'id': 'science',
      'title': 'Наука',
      'icon': '🔬',
      'testCount': 18,
      'color': 0xFF4CC9F0,
    },
    {
      'id': 'language',
      'title': 'Языки',
      'icon': '📚',
      'testCount': 22,
      'color': 0xFFF72585,
    },
  ];

  static const List<Map<String, dynamic>> offlineTests = [
    {
      'id': 'math_7',
      'title': 'Математика 7 класс',
      'size': '25 МБ',
      'status': 'Загружено',
    },
    {
      'id': 'history_ancient',
      'title': 'История Древнего мира',
      'size': '18 МБ',
      'status': 'Загружено',
    },
  ];
}
