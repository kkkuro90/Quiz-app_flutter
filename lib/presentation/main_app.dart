import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/colors.dart';
import '../data/repositories/auth_repository.dart';
import 'shared/widgets/gradient_background.dart';
import 'teacher/screens/teacher_home_screen.dart';
import 'student/screens/student_home_screen.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthRepository>().currentUser?.role ?? 'student';

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          '📚 Quiz',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await context.read<AuthRepository>().logout();
                        },
                        tooltip: 'Выйти',
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Интерактивные квизы для образования',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Content - показываем только нужную страницу
            Expanded(
              child: userRole == 'teacher'
                  ? const TeacherHomeScreen()
                  : const StudentHomeScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
