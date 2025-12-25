import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository with ChangeNotifier {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;

  AuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    _isLoading = true;
    notifyListeners();

    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      _isAuthenticated = true;
      _currentUser = await _loadUserFromFirestore(fbUser);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<User> _loadUserFromFirestore(fb.User fbUser) async {
    try {
      final userDoc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return User(
          id: fbUser.uid,
          email: data['email'] ?? fbUser.email ?? '',
          name: data['name'] ?? fbUser.displayName ?? fbUser.email ?? 'Пользователь',
          role: data['role'] ?? 'student',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? fbUser.metadata.creationTime,
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? fbUser.metadata.lastSignInTime,
        );
      }
    } catch (e) {
      debugPrint('Ошибка загрузки пользователя из Firestore: $e');
    }
    return _userFromFirebase(fbUser);
  }

  String _extractRole(fb.User fbUser, String fallbackRole) {
    final displayName = fbUser.displayName ?? '';
    if (displayName.contains('[teacher]')) return 'teacher';
    if (displayName.contains('[student]')) return 'student';
    return fallbackRole;
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
      final testUser = _checkTestUser(email, password);
      if (testUser != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _currentUser = testUser;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return;
      }
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = await _loadUserFromFirestore(credential.user!);
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

  User? _checkTestUser(String email, String password) {
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
      final testUser = _checkTestUser(email, password);
      if (testUser != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _currentUser = testUser;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return;
      }
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final fbUser = credential.user!;
      
      await _firestore.collection('users').doc(fbUser.uid).set({
        'userId': fbUser.uid,
        'email': email,
        'role': role,
        'name': email.split('@')[0],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await fbUser.updateDisplayName('$email [$role]');
      
      _currentUser = await _loadUserFromFirestore(fbUser);
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
