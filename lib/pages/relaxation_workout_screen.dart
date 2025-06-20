import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flowstate/pages/home_page.dart'; // Импортируем
import 'workout_detail_screen.dart';

class RelaxationWorkoutScreen extends StatelessWidget {
  const RelaxationWorkoutScreen({super.key});

  final List<Map<String, dynamic>> _workouts = const [
    {
      'name': 'Тест',
      'exercises': [
        { 'name': 'Анантасана',
          'image1': 'assets/Anantasana_1.svg',
          'image2': 'assets/Anantasana_2.svg',
          'image3': 'assets/Anantasana_3.svg'
        },
        {
           'name': 'Бхуджангасана', 
          'image1': 'assets/Bhujangasana_1.svg', 
          'image2': 'assets/Bhujangasana_2.svg', 
          'image3': 'assets/Bhujangasana_3.svg'
        },
        {
           'name': 'Маха Мудра',
          'image1': 'assets/MahaMudra_1.svg',
          'image2': 'assets/MahaMudra_2.svg',
          'image3': 'assets/MahaMudra_3.svg'
        },
      ],
    },
  ];

  Widget _buildWorkoutCard(BuildContext context, Map<String, dynamic> workout) {
    final exercises = List<Map<String, dynamic>>.from(workout['exercises']);
    final exercisesForDetail = List<Map<String, String>>.from(exercises.map((e) => e.map((key, value) => MapEntry(key, value.toString()))));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3), ), ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text( workout['name'], style: const TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, ), ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push( context, MaterialPageRoute( builder: (context) => WorkoutDetailScreen(
                      workoutName: workout['name'],
                      exercises: exercisesForDetail,
                    ),
                    ),
                    );
                  },
                  style: ElevatedButton.styleFrom( backgroundColor: const Color.fromARGB(255, 155, 193, 102), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10), ), ),
                  child: const Text('Начать', style: TextStyle( fontWeight: FontWeight.bold, color: Colors.white, ), ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.group_add, color: Color(0xFF92A880)),
                onPressed: () => showInviteFriendDialog(context, workout['name'], exercises),
                style: IconButton.styleFrom( side: const BorderSide(color: Color(0xFF92A880), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), ),
              ),
            ],
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
          Positioned.fill( child: SvgPicture.asset( 'assets/background.svg', fit: BoxFit.cover, ), ),
          SafeArea(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                      child: Text( 'Тренировка: Расслабление', textAlign: TextAlign.center, style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black, ), ),
                    ),
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: const Icon( Icons.arrow_back, color: Colors.black, size: 30, ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
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