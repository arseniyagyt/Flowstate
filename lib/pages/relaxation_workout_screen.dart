import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'workout_detail_screen.dart'; // New screen for workout details

class RelaxationWorkoutScreen extends StatelessWidget {
  const RelaxationWorkoutScreen({super.key});

  // Predefined workouts, each with 5 exercises
  final List<Map<String, dynamic>> _workouts = const [
    {
      'name': 'Тест',
      'exercises': [
        {
          'name': 'Анантасана',
          'image1': 'assets/Anantasana_1.svg',
          'image2': 'assets/Anantasana_2.svg',
          'image3': 'assets/Anantasana_3.svg',
        },
        {
          'name': 'Бхуджангасана',
          'image1': 'assets/Bhujangasana_1.svg',
          'image2': 'assets/Bhujangasana_2.svg',
          'image3': 'assets/Bhujangasana_3.svg',
        },
        {
          'name': 'Маха Мудра',
          'image1': 'assets/MahaMudra_1.svg',
          'image2': 'assets/MahaMudra_2.svg',
          'image3': 'assets/MahaMudra_3.svg',
        },
        {
          'name': 'Паригхасана',
          'image1': 'assets/Parigkhasana_1.svg',
          'image2': 'assets/Parigkhasana_2.svg',
          'image3': 'assets/Parigkhasana_3.svg',
        },
        {
          'name': 'Триконасана',
          'image1': 'assets/Trikonasana_1.svg',
          'image2': 'assets/Trikonasana_2.svg',
          'image3': 'assets/Trikonasana_3.svg',
        },
      ],
    },
  ];

  Widget _buildWorkoutCard(BuildContext context, Map<String, dynamic> workout) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              workout['name'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutDetailScreen(
                    workoutName: workout['name'],
                    exercises: List<Map<String, String>>.from(workout['exercises']),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 155, 193, 102),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(100, 40),
            ),
            child: const Text(
              'Начать',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/background.svg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                        child: const Text(
                          'Тренировка: Расслабление',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 30,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                // Workout list
                Expanded(
                  child: ListView.builder(
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) => _buildWorkoutCard(context, _workouts[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}