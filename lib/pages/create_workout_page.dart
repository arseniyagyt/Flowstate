import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/snackbar.dart';

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  _CreateWorkoutScreenState createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final List<Map<String, String>> _exerciseOptions = [
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
    {
      'name': 'Пашчимоттанасана',
      'image1': 'assets/idk_1.svg',
      'image2': 'assets/idk_2.svg',
      'image3': 'assets/idk_3.svg',
    },
    {
      'name': 'Баласана',
      'image1': 'assets/Balasana_1.svg',
      'image2': 'assets/Balasana_2.svg',
      'image3': 'assets/Balasana_3.svg',
    },
    {
      'name': 'Падмасана',
      'image1': 'assets/Padmasana_1.svg',
      'image2': 'assets/Padmasana_2.svg',
      'image3': 'assets/Padmasana_3.svg',
    },
    {
      'name': 'Супта Вирасана',
      'image1': 'assets/SuptaVirasana_1.svg',
      'image2': 'assets/SuptaVirasana_2.svg',
      'image3': 'assets/SuptaVirasana_3.svg',
    },
    {
      'name': 'Шавасана',
      'image1': 'assets/Shavasana_1.svg',
      'image2': 'assets/Shavasana_1.svg',
      'image3': 'assets/Shavasana_1.svg',
    },
    {
      'name': 'Супта Свастикасана',
      'image1': 'assets/SuptaSvastikasana_1.svg',
      'image2': 'assets/SuptaSvastikasana_2.svg',
      'image3': 'assets/SuptaSvastikasana_2.svg',
    },
  ];

  final List<String> _selectedExercises = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _workoutNameController = TextEditingController();

  void _selectExercise(String exercise) {
    setState(() {
      if (_selectedExercises.contains(exercise)) {
        _selectedExercises.remove(exercise);
      } else {
        _selectedExercises.add(exercise);
      }
    });
  }

  Future<void> _createWorkout() async {
    if (_selectedExercises.isEmpty) {
      SnackBarService.showSnackBar(context, 'Выберите хотя бы одно упражнение', true);
      return;
    }
    _showNameInputDialog();
  }

  Future<void> _saveWorkout() async {
    final workoutName = _workoutNameController.text.trim();
    if (workoutName.isEmpty) {
      SnackBarService.showSnackBar(context, 'Введите название тренировки', true);
      return;
    }
    final user = _auth.currentUser;
    if (user == null) {
      SnackBarService.showSnackBar(context, 'Пользователь не авторизован', true);
      return;
    }
    try {
      final exercises = _selectedExercises.map((exercise) {
        final exerciseData = _exerciseOptions.firstWhere((e) => e['name'] == exercise);
        return {
          'name': exercise,
          'image1': exerciseData['image1'],
          'image2': exerciseData['image2'],
          'image3': exerciseData['image3'],
        };
      }).toList();

      await _firestore.collection('user_workouts').add({
        'userId': user.uid,
        'name': workoutName,
        'exercises': exercises,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      SnackBarService.showSnackBar(context, 'Тренировка сохранена', false);
      Navigator.pop(context); // Закрываем диалог
      Navigator.pop(context); // Возвращаемся на предыдущий экран
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка сохранения: $e', true);
    }
  }

  void _showNameInputDialog() {
    _workoutNameController.clear(); // Очищаем поле перед показом
    showDialog(
      context: context,
      barrierDismissible: false, // Запрещаем закрытие по клику вне диалога
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Блюр фона
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Название тренировки',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _workoutNameController,
                    decoration: InputDecoration(
                      labelText: 'Введите название',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Закрываем диалог
                        },
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _saveWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseCard(Map<String, String> exercise, bool isSelected) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _selectExercise(exercise['name']!);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF92A880) : Colors.transparent,
            width: 4,
          ),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SvgPicture.asset(
                exercise['image1']!,
                width: 120,
                height: 120,
                fit: BoxFit.fitWidth,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise['name']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                                size: 30,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            const Expanded(
                              child: Text(
                                "Выберите упражнения для тренировки",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // Placeholder for symmetry
                          ],
                        ),
                        const SizedBox(height: 20),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: _exerciseOptions.map((exercise) {
                            final isSelected = _selectedExercises.contains(exercise['name']);
                            return _buildExerciseCard(exercise, isSelected);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _createWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Создать тренировку',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
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