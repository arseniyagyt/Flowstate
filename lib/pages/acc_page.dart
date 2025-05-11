import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flowstate/services/colors.dart';
import 'package:flowstate/services/snackbar.dart';
import 'login_page.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool canResendEmail = true;
  bool isLoading = false;

  // Контроллеры для полей ввода
  final TextEditingController _firstNameController = TextEditingController(text: "Ксения");
  final TextEditingController _lastNameController = TextEditingController(text: "Сивкова");
  final TextEditingController _nicknameController = TextEditingController(text: "@ksksksesha");
  final TextEditingController _emailController = TextEditingController();

  // Переменные для настроек
  bool _isNotificationsEnabled = true;
  double _soundVolume = 50.0;
  double _musicVolume = 50.0;

  @override
  void initState() {
    super.initState();
    _emailController.text = user?.email ?? "Не указан";
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> sendVerificationEmail() async {
    try {
      setState(() => canResendEmail = false);

      await user?.sendEmailVerification();

      if (!mounted) return;
      SnackBarService.showSnackBar(
        context,
        'Письмо с подтверждением отправлено на ${user?.email}',
        false,
      );

      await Future.delayed(const Duration(seconds: 30));
      setState(() => canResendEmail = true);
    } catch (e) {
      if (!mounted) return;
      SnackBarService.showSnackBar(
        context,
        'Ошибка отправки письма: $e',
        true,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarService.showSnackBar(
        context,
        'Ошибка выхода: $e',
        true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

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
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(226, 255, 255, 255),
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(28, 0, 0, 0),
                          spreadRadius: 3,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          "Профиль",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: avatarBorderColor,
                                  width: 2,
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(
                                  'https://sun9-30.userapi.com/impg/MfmN7sNobhqkRFe5nQzQdm_UO2-EEoOurKRfBw/0Z6qwfZjPaE.jpg?size=1620x2160&quality=95&sign=e2bbb567dd1109494bc41319f5a4e3f0&type=album',
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                decoration: BoxDecoration(
                                  color: highlightBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _nicknameController,
                                      decoration: InputDecoration(
                                        labelText: "Ник",
                                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: secondaryColor),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _firstNameController,
                                            decoration: InputDecoration(
                                              labelText: "Имя",
                                              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Colors.grey),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: secondaryColor),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.03),
                                        Expanded(
                                          child: TextField(
                                            controller: _lastNameController,
                                            decoration: InputDecoration(
                                              labelText: "Фамилия",
                                              labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Colors.grey),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: secondaryColor),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    TextField(
                                      controller: _emailController,
                                      readOnly: true, // Email нельзя редактировать
                                      decoration: InputDecoration(
                                        labelText: "Email",
                                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: secondaryColor),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (user != null && !user!.emailVerified) ...[
                          SizedBox(height: screenHeight * 0.01),
                          const Text(
                            'Email не подтверждён',
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: canResendEmail ? sendVerificationEmail : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text(
                                'Подтвердить Email',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: screenHeight * 0.015),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: ElevatedButton(
                                onPressed: () {
                                  SnackBarService.showSnackBar(
                                    context,
                                    "Сохранено:\nНик: ${_nicknameController.text}\nИмя: ${_firstNameController.text}\nФамилия: ${_lastNameController.text}",
                                    false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text(
                                  "Сохранить",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            SizedBox(
                              width: 120,
                              child: OutlinedButton(
                                onPressed: signOut,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: const Text(
                                  "Выйти",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        const Text(
                          "Настройки",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color: highlightBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Звук",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "${_soundVolume.round()}%",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _soundVolume,
                                min: 0,
                                max: 100,
                                divisions: 100,
                                activeColor: secondaryColor,
                                inactiveColor: Colors.grey,
                                onChanged: (value) {
                                  setState(() => _soundVolume = value);
                                },
                                onChangeEnd: (value) {
                                  SnackBarService.showSnackBar(
                                    context,
                                    "Громкость звука установлена на ${value.round()}%",
                                    false,
                                  );
                                },
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Музыка",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "${_musicVolume.round()}%",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _musicVolume,
                                min: 0,
                                max: 100,
                                divisions: 100,
                                activeColor: secondaryColor,
                                inactiveColor: Colors.grey,
                                onChanged: (value) {
                                  setState(() => _musicVolume = value);
                                },
                                onChangeEnd: (value) {
                                  SnackBarService.showSnackBar(
                                    context,
                                    "Громкость музыки установлена на ${value.round()}%",
                                    false,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color: highlightBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Уведомления",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              Switch(
                                value: _isNotificationsEnabled,
                                onChanged: (value) {
                                  setState(() => _isNotificationsEnabled = value);
                                  SnackBarService.showSnackBar(
                                    context,
                                    "Уведомления ${value ? 'включены' : 'выключены'}",
                                    false,
                                  );
                                },
                                activeColor: secondaryColor,
                              ),
                            ],
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