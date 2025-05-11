import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/colors.dart';
import 'relaxation_workout_screen.dart';
import 'stretching_workout_screen.dart';

class ReadyWorkoutsScreen extends StatelessWidget {
  const ReadyWorkoutsScreen({super.key});

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
          // Кнопка возврата назад
          Positioned(
            top: 30, // Отступ сверху, чтобы не прилипала к краю
            left: 26, // Отступ слева
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black, // Цвет иконки
                size: 30, // Размер иконки
              ),
              onPressed: () {
                Navigator.pop(context); // Возврат на предыдущий экран
              },
            ),
          ),
          // Основное содержимое
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Блок "Расслабление"
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RelaxationWorkoutScreen(),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        // Контейнер для границы с градиентом
                        Container(
                          width: 300,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                gradientColor, // Синий цвет снизу
                                primaryColor, // Прозрачный сверху
                              ],
                              stops: [0.0, 0.5],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0), // Ширина границы 20 пикселей
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white, // Внутренний фон контейнера
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: SvgPicture.asset(
                                  'assets/relaxation.svg',
                                  fit: BoxFit.cover,
                                  width: 260, // Учитываем ширину границы
                                  height: 160, // Учитываем ширину границы
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Расслабление",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Блок "Растяжка"
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StretchingWorkoutScreen(),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        // Контейнер для границы с градиентом
                        Container(
                          width: 300,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                gradientColor, // Синий цвет снизу
                                primaryColor, // Прозрачный сверху
                              ],
                              stops: [0.0, 0.5],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0), // Ширина границы 20 пикселей
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white, // Внутренний фон контейнера
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: SvgPicture.asset(
                                  'assets/stretching.svg',
                                  fit: BoxFit.cover,
                                  width: 260, // Учитываем ширину границы
                                  height: 160, // Учитываем ширину границы
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Растяжка",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}