import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class AuthRepository with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;

  AuthRepository() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      _isAuthenticated = true;
      // Загрузка данных пользователя
      _currentUser = User(
        id: '1',
        email: 'teacher@example.com',
        name: 'Учитель',
        role: 'teacher',
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Имитация API запроса
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', 'demo_token');

    _isAuthenticated = true;
    _currentUser = User(
      id: '1',
      email: email,
      name: 'Учитель',
      role: 'teacher',
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Имитация API запроса
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', 'demo_token');

    _isAuthenticated = true;
    _currentUser = User(
      id: '1',
      email: email,
      name: 'Новый пользователь',
      role: 'teacher',
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
