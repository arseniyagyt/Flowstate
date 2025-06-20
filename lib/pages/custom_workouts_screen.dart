import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowstate/pages/home_page.dart'; // Импортируем
import '../services/snackbar.dart';
import 'custom_workout_detail_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomWorkoutsScreen extends StatefulWidget {
  const CustomWorkoutsScreen({super.key});

  @override
  _CustomWorkoutsScreenState createState() => _CustomWorkoutsScreenState();
}

class _CustomWorkoutsScreenState extends State<CustomWorkoutsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _customWorkouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomWorkouts();
  }

  Future<void> _loadCustomWorkouts() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final snapshot = await _firestore.collection('user_workouts').where('userId', isEqualTo: user.uid).get();
      setState(() {
        _customWorkouts = snapshot.docs.map((doc) {
          final data = doc.data();
          return { 'id': doc.id, 'name': data['name'], 'exercises': List<Map<String, dynamic>>.from(data['exercises']), };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) SnackBarService.showSnackBar(context, 'Ошибка загрузки: $e', true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorkout(String workoutId) async {
    try {
      await _firestore.collection('user_workouts').doc(workoutId).delete();
      await _loadCustomWorkouts(); // Обновляем список после удаления
      if (mounted) SnackBarService.showSnackBar(context, 'Тренировка удалена', false);
    } catch (e) {
      if (mounted) SnackBarService.showSnackBar(context, 'Ошибка удаления: $e', true);
    }
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final exercises = List<Map<String, dynamic>>.from(workout['exercises']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all( color: const Color(0xFF92A880), width: 4, ),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3), ), ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded( child: Text( workout['name'], style: const TextStyle( fontSize: 22, fontWeight: FontWeight.bold, ), ), ),
              IconButton( icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _deleteWorkout(workout['id']), tooltip: "Удалить тренировку",),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push( context, MaterialPageRoute( builder: (context) => CustomWorkoutDetailScreen(
                      workoutName: workout['name'],
                      exercises: exercises,
                    ),
                    ),
                    ).then((_) => _loadCustomWorkouts()); // Обновляем на случай, если пользователь вернется назад
                  },
                  style: ElevatedButton.styleFrom( backgroundColor: const Color.fromARGB(255, 155, 193, 102), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10), ), minimumSize: const Size(0, 44)),
                  child: const Text( 'Начать', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, ), ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.group_add, color: Color(0xFF92A880)),
                onPressed: () => showInviteFriendDialog(context, workout['name'], exercises),
                tooltip: "Пригласить друга",
                style: IconButton.styleFrom( side: const BorderSide(color: Color(0xFF92A880), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(44, 44)),
              )
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
          Positioned.fill( child: SvgPicture.asset('assets/background.svg', fit: BoxFit.cover), ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded( child: Text("Созданные тренировки", textAlign: TextAlign.center, style: TextStyle( fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black, ), ), ),
                      const SizedBox(width: 48), // Для центрирования
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _customWorkouts.isEmpty
                      ? const Center( child: Text('У вас пока нет созданных тренировок', style: TextStyle(fontSize: 18)), )
                      : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _customWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = _customWorkouts[index];
                      return _buildWorkoutCard(workout);
                    },
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