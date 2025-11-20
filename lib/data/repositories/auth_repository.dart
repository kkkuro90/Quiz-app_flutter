import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthRepository with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isTeacher => _currentUser?.role == 'teacher';

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // TODO: Реализовать реальную авторизацию через Firebase/Backend
    await Future.delayed(const Duration(seconds: 2));

    // Временная заглушка для тестирования
    _currentUser = User(
      id: '1',
      email: email,
      name: 'Test User',
      role: email.contains('teacher') ? 'teacher' : 'student',
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register(String email, String password, String name, String role) async {
    _isLoading = true;
    notifyListeners();

    // TODO: Реализовать реальную регистрацию
    await Future.delayed(const Duration(seconds: 2));

    _currentUser = User(
      id: '1',
      email: email,
      name: name,
      role: role,
      createdAt: DateTime.now(),
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}