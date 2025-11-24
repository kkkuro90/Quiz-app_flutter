import 'package:flutter/material.dart';
import 'teacher/screens/teacher_home_screen.dart';
import 'student/screens/student_home_screen.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz App'),
          backgroundColor: Colors.blue,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.school), text: 'Учитель'),
              Tab(icon: Icon(Icons.person), text: 'Ученик'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TeacherHomeScreen(),
            StudentHomeScreen(),
          ],
        ),
      ),
    );
  }
}
