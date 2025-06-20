import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flowstate/services/snackbar.dart';
import '../services/colors.dart';
import 'login_page.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool isLoading = false;
  final TextEditingController emailTextInputController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailTextInputController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailTextInputController.text.trim(),
      );

      if (!mounted) return;

      SnackBarService.showSnackBar(
        context,
        'Письмо для сброса пароля отправлено на ${emailTextInputController.text.trim()}',
        false,
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('Ошибка сброса пароля: ${e.code}');

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Пользователь с таким email не найден';
          break;
        case 'invalid-email':
          errorMessage = 'Некорректный email адрес';
          break;
        case 'too-many-requests':
          errorMessage = 'Слишком много запросов. Попробуйте позже';
          break;
        default:
          errorMessage = 'Произошла ошибка. Попробуйте еще раз';
      }

      if (mounted) {
        SnackBarService.showSnackBar(context, errorMessage, true);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Прозрачный фон для устранения белой коробки
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
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Сброс пароля',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Введите email, связанный с вашим аккаунтом, и мы отправим ссылку для сброса пароля:',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: emailTextInputController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: accentColor),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите email';
                            }
                            if (!EmailValidator.validate(value)) {
                              return 'Введите корректный email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : resetPassword,
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
                                    'Отправить ссылку для сброса',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: textColor,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Назад к входу',
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
          ),
        ],
      ),
    );
  }
}