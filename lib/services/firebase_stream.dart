import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowstate/pages/login_page.dart';
import 'package:flowstate/pages/home_page.dart';

class FirebaseStream extends StatelessWidget {
  const FirebaseStream({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Произошла ошибка')),
          );
        }

        // Если пользователь авторизован, показываем главный экран.
        // Главный экран (HomeScreen) сам настроит прослушиватель уведомлений.
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Если пользователь не авторизован, показываем экран входа.
        else {
          return const LoginScreen();
        }
      },
    );
  }
}