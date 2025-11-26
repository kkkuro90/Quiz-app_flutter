import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/quiz_repository.dart';
import 'core/services/notification_service.dart';
import 'presentation/teacher/controllers/teacher_dashboard_controller.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthRepository()),
        ChangeNotifierProvider(create: (_) => QuizRepository()),
        Provider(create: (_) => NotificationService()),
        ChangeNotifierProxyProvider2<QuizRepository, NotificationService,
            TeacherDashboardController>(
          create: (context) => TeacherDashboardController(
            quizRepository: context.read<QuizRepository>(),
            notificationService: context.read<NotificationService>(),
          ),
          update: (context, quizRepo, notificationService, controller) {
            if (controller == null) {
              return TeacherDashboardController(
                quizRepository: quizRepo,
                notificationService: notificationService,
              );
            }
            controller.updateSources(quizRepo, notificationService);
            return controller;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const App(),
    );
  }
}
