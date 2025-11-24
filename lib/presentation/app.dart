import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/auth_repository.dart';
import 'auth/login_screen.dart';
import 'main_app.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(
      builder: (context, authRepo, child) {
        if (authRepo.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return authRepo.isAuthenticated ? const MainApp() : const LoginScreen();
      },
    );
  }
}
