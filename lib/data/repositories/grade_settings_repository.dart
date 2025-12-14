import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Repository для управления настройками оценок
class GradeSettingsRepository with ChangeNotifier {
  final FirebaseFirestore _db;

  String? _currentTeacherId;
  Map<String, double>? _settings;

  GradeSettingsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _listenToSettings();
  }

  void _listenToSettings() {
    // Отслеживаем изменения настроек для текущего учителя
    // Этот метод будет вызван при изменении teacherId
  }

  /// Обновляем текущего учителя и загружаем его настройки
  void setCurrentTeacher(String teacherId) {
    if (_currentTeacherId == teacherId) return;
    
    _currentTeacherId = teacherId;
    _loadSettings(teacherId);
  }

  /// Загружаем настройки для указанного учителя
  Future<void> _loadSettings(String teacherId) async {
    try {
      final doc = await _db.collection('grade_settings').doc(teacherId).get();
      if (doc.exists) {
        _settings = _parseThresholds(doc.data() as Map<String, dynamic>);
      } else {
        // Используем значения по умолчанию
        _settings = {
          '5': 0.85,
          '4': 0.70,
          '3': 0.50,
          '2': 0.0,
        };
      }
      notifyListeners();
    } catch (e) {
      // Используем значения по умолчанию в случае ошибки
      _settings = {
        '5': 0.85,
        '4': 0.70,
        '3': 0.50,
        '2': 0.0,
      };
      notifyListeners();
    }
  }

  /// Сохраняем настройки оценок
  Future<void> saveSettings(Map<String, double> thresholds) async {
    if (_currentTeacherId == null) {
      throw Exception('Teacher ID is not set. Call setCurrentTeacher first.');
    }

    final data = {
      'teacherId': _currentTeacherId,
      'thresholds': _serializeThresholds(thresholds),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('grade_settings').doc(_currentTeacherId).set(data);
    _settings = thresholds;
    notifyListeners();
  }

  /// Получаем текущие настройки оценок
  Map<String, double> get currentSettings {
    if (_settings != null) {
      return Map.unmodifiable(_settings!);
    }
    
    // Значения по умолчанию
    return {
      '5': 0.85,
      '4': 0.70,
      '3': 0.50,
      '2': 0.0,
    };
  }

  /// Расчет оценки по проценту
  String calculateGrade(double percentage) {
    final thresholds = currentSettings;
    if (percentage >= thresholds['5']!) return '5';
    if (percentage >= thresholds['4']!) return '4';
    if (percentage >= thresholds['3']!) return '3';
    return '2';
  }

  Map<String, dynamic> _serializeThresholds(Map<String, double> thresholds) {
    final result = <String, dynamic>{};
    for (final entry in thresholds.entries) {
      result[entry.key] = entry.value;
    }
    return result;
  }

  Map<String, double> _parseThresholds(Map<String, dynamic> data) {
    final thresholds = <String, double>{};
    final rawThresholds = data['thresholds'] as Map<String, dynamic>?;
    
    if (rawThresholds != null) {
      for (final entry in rawThresholds.entries) {
        thresholds[entry.key] = entry.value.toDouble();
      }
    }
    
    return thresholds;
  }
}