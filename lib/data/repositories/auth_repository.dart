import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';

/// AuthRepository: обертка над Firebase Auth (email/password)
class AuthRepository with ChangeNotifier {
  final fb.FirebaseAuth _auth;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;

  AuthRepository({fb.FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? fb.FirebaseAuth.instance {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      _isAuthenticated = true;
      _currentUser = _userFromFirebase(fbUser);
    }

    _isLoading = false;
    notifyListeners();
  }

  String _extractRole(fb.User fbUser, String fallbackRole) {
    final displayName = fbUser.displayName ?? '';
    if (displayName.contains('[teacher]')) return 'teacher';
    if (displayName.contains('[student]')) return 'student';
    return fallbackRole;
  }

  Future<void> _persistRoleToProfile(fb.User fbUser, String role) async {
    final displayName = fbUser.displayName ?? '';
    if (displayName.contains('[teacher]') || displayName.contains('[student]')) {
      return;
    }
    await fbUser.updateDisplayName('${fbUser.email ?? fbUser.uid} [$role]');
  }

  User _userFromFirebase(fb.User fbUser, {String fallbackRole = 'student'}) {
    return User(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      name: fbUser.displayName ?? fbUser.email ?? 'Пользователь',
      role: _extractRole(fbUser, fallbackRole),
      createdAt: fbUser.metadata.creationTime,
      updatedAt: fbUser.metadata.lastSignInTime,
    );
  }

  Future<void> login(
    String email,
    String password, {
    String role = 'student',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Проверка тестовых пользователей (для демо без базы данных)
      final testUser = _checkTestUser(email, password);
      if (testUser != null) {
        await Future.delayed(const Duration(milliseconds: 500)); // Имитация задержки
        _currentUser = testUser;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Обычный вход через Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = _userFromFirebase(credential.user!, fallbackRole: role);
      _isAuthenticated = true;
      await _persistRoleToProfile(credential.user!, _currentUser!.role);
    } on fb.FirebaseAuthException {
      _isAuthenticated = false;
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  User? _checkTestUser(String email, String password) {
    // Тестовый учитель
    if (email.toLowerCase() == 'teacher' && password == '123qwe') {
      return User(
        id: 'test-teacher-001',
        email: 'teacher@test.com',
        name: 'Teacher',
        role: 'teacher',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    // Тестовый ученик
    if (email.toLowerCase() == 'child' && password == '123456') {
      return User(
        id: 'test-student-001',
        email: 'child@test.com',
        name: 'Child',
        role: 'student',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    return null;
  }

  Future<void> register(
    String email,
    String password, {
    String role = 'student',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Проверка тестовых пользователей (для демо без базы данных)
      final testUser = _checkTestUser(email, password);
      if (testUser != null) {
        await Future.delayed(const Duration(milliseconds: 500)); // Имитация задержки
        _currentUser = testUser;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Обычная регистрация через Firebase
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName('${email} [$role]');
      _currentUser = _userFromFirebase(credential.user!, fallbackRole: role);
      _isAuthenticated = true;
    } on fb.FirebaseAuthException {
      _isAuthenticated = false;
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
