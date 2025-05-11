import 'package:flutter/material.dart';

class StretchingWorkoutScreen extends StatelessWidget {
  const StretchingWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Тренировка: Растяжка"),
      ),
      body: const Center(
        child: Text(
          "Экран тренировки 'Растяжка' (в разработке)",
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}