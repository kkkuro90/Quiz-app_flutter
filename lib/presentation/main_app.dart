import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth_repository.dart';
import 'auth/screens/login_screen.dart';
import 'teacher/screens/teacher_home_screen.dart';
import 'student/screens/student_home_screen.dart';
import 'shared/widgets/loading_screen.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = context.watch<AuthRepository>();

    if (authRepo.isLoading) {
      return const LoadingScreen();
    }

    if (!authRepo.isLoggedIn) {
      return const LoginScreen();
    }

    // В зависимости от роли пользователя показываем соответствующий интерфейс
    return authRepo.isTeacher 
        ? const TeacherHomeScreen() 
        : const StudentHomeScreen();
  }
}