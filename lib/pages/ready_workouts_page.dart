import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/colors.dart';
import 'relaxation_workout_screen.dart';
import 'stretching_workout_screen.dart';
import 'custom_workouts_screen.dart';

class ReadyWorkoutsScreen extends StatelessWidget {
  const ReadyWorkoutsScreen({super.key});

  Widget _buildWorkoutBlock({
    required String title,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [gradientColor, primaryColor],
                  stops: [0.0, 0.5],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SvgPicture.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      width: 260,
                      height: 160,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/background.svg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 30,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "Готовые тренировки",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildWorkoutBlock(
                          title: "Расслабление",
                          imageAsset: 'assets/relaxation.svg',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RelaxationWorkoutScreen(),
                            ),
                          ),
                        ),
                        _buildWorkoutBlock(
                          title: "Растяжка",
                          imageAsset: 'assets/stretching.svg',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StretchingWorkoutScreen(),
                            ),
                          ),
                        ),
                        _buildWorkoutBlock(
                          title: "Созданные тренировки",
                          imageAsset: 'assets/idk_1.svg',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomWorkoutsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
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