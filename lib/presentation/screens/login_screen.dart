import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String _selectedRole = 'student';

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final authRepo = context.read<AuthRepository>();

      try {
        if (_isLogin) {
          await authRepo.login(
            _emailController.text,
            _passwordController.text,
            role: _selectedRole,
          );
        } else {
          await authRepo.register(
            _emailController.text,
            _passwordController.text,
            role: _selectedRole,
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? 'Вход' : 'Регистрация',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (value.length < 6) {
                    return 'Пароль должен быть не менее 6 символов';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Роль:'),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Ученик'),
                    selected: _selectedRole == 'student',
                    onSelected: (_) =>
                        setState(() => _selectedRole = 'student'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Учитель'),
                    selected: _selectedRole == 'teacher',
                    onSelected: (_) =>
                        setState(() => _selectedRole = 'teacher'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Нет аккаунта? Зарегистрируйтесь'
                      : 'Уже есть аккаунт? Войдите',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
