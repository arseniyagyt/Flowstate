import 'package:flutter/material.dart';

class RelaxationWorkoutScreen extends StatelessWidget {
  const RelaxationWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Тренировка: Расслабление"),
      ),
      body: const Center(
        child: Text(
          "Экран тренировки 'Расслабление' (в разработке)",
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}