import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:flowstate/services/snackbar.dart';

import '../services/colors.dart';

import 'home_page.dart';

import 'signup_page.dart';



class LoginScreen extends StatefulWidget {

  const LoginScreen({super.key});



  @override

  LoginScreenState createState() => LoginScreenState();

}



class LoginScreenState extends State<LoginScreen> {

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;



  @override

  void dispose() {

    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();

  }



  Future<void> login() async {

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {

      SnackBarService.showSnackBar(

        context,

        'Заполните все поля',

        true,

      );

      return;

    }



    setState(() => isLoading = true);



    try {

      await FirebaseAuth.instance.signInWithEmailAndPassword(

        email: _emailController.text.trim(),

        password: _passwordController.text.trim(),

      );



      if (!mounted) return;



      // ИЗМЕНЕНО: Навигация исправлена на HomeScreen

      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(builder: (context) => const HomeScreen()),

            (route) => false,

      );

    } on FirebaseAuthException catch (e) {

      String errorMessage;

      switch (e.code) {

        case 'user-not-found':

        case 'wrong-password':

          errorMessage = 'Неверный email или пароль';

          break;

        case 'too-many-requests':

          errorMessage = 'Слишком много попыток. Попробуйте позже';

          break;

        case 'user-disabled':

          errorMessage = 'Аккаунт отключен';

          break;

        default:

          errorMessage = 'Ошибка входа: ${e.message}';

      }



      if (!mounted) return;

      SnackBarService.showSnackBar(context, errorMessage, true);

    } finally {

      if (mounted) {

        setState(() => isLoading = false);

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      body: Stack(

        children: [

          // SVG-фон

          Positioned.fill(

            child: SvgPicture.asset(

              'assets/background.svg',

              fit: BoxFit.cover,

            ),

          ),

          // Основное содержимое

          SafeArea(

            child: Center(

              child: Padding(

                padding: const EdgeInsets.all(16.0),

                child: Container(

                  padding: const EdgeInsets.all(24.0),

                  decoration: BoxDecoration(

                    color: backColor,

                    borderRadius: BorderRadius.circular(20.0),

                    boxShadow: [

                      BoxShadow(

                        color: const Color.fromARGB(28, 0, 0, 0),

                        spreadRadius: 5,

                        blurRadius: 10,

                        offset: const Offset(0, 5),

                      ),

                    ],

                  ),

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      const Text(

                        "Вход",

                        style: TextStyle(

                          fontSize: 32,

                          fontWeight: FontWeight.bold,

                          color: Colors.black,

                        ),

                      ),

                      const SizedBox(height: 32),

                      TextField(

                        controller: _emailController,

                        decoration: InputDecoration(

                          labelText: "Email",

                          labelStyle: const TextStyle(color: Colors.grey),

                          border: OutlineInputBorder(

                            borderRadius: BorderRadius.circular(10),

                            borderSide: const BorderSide(color: Colors.grey),

                          ),

                          focusedBorder: OutlineInputBorder(

                            borderRadius: BorderRadius.circular(10),

                            borderSide: const BorderSide(color: accentColor),

                          ),

                        ),

                        keyboardType: TextInputType.emailAddress,

                      ),

                      const SizedBox(height: 16),

                      TextField(

                        controller: _passwordController,

                        decoration: InputDecoration(

                          labelText: "Пароль",

                          labelStyle: const TextStyle(color: Colors.grey),

                          border: OutlineInputBorder(

                            borderRadius: BorderRadius.circular(10),

                            borderSide: const BorderSide(color: Colors.grey),

                          ),

                          focusedBorder: OutlineInputBorder(

                            borderRadius: BorderRadius.circular(10),

                            borderSide: const BorderSide(color: accentColor),

                          ),

                        ),

                        obscureText: true,

                      ),

                      const SizedBox(height: 24),

                      SizedBox(

                        width: double.infinity,

                        child: ElevatedButton(

                          onPressed: isLoading ? null : login,

                          style: ElevatedButton.styleFrom(

                            backgroundColor: primaryColor,

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(15),

                            ),

                            padding: const EdgeInsets.symmetric(vertical: 16),

                          ),

                          child: isLoading

                              ? const CircularProgressIndicator(color: textColor)

                              : const Text(

                            "Войти",

                            style: TextStyle(

                              fontSize: 18,

                              color: textColor,

                            ),

                          ),

                        ),

                      ),

                      const SizedBox(height: 16),

                      TextButton(

                        onPressed: () {

                          Navigator.pushNamed(context, '/reset_password');

                        },

                        child: const Text(

                          "Забыли пароль?",

                          style: TextStyle(

                            fontSize: 14,

                            color: Color.fromARGB(255, 62, 62, 62),

                          ),

                        ),

                      ),

                      const SizedBox(),

                      TextButton(

                        onPressed: () {

                          Navigator.pushReplacement(

                            context,

                            MaterialPageRoute(builder: (context) => const SignUpScreen()),

                          );

                        },

                        child: const Text(

                          "Нет аккаунта? Зарегистрироваться",

                          style: TextStyle(

                            fontSize: 14,

                            color: Color.fromARGB(255, 62, 62, 62),

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

}