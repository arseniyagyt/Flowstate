import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowstate/services/snackbar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _workouts = {};
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      _loadWorkouts();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackBarService.showSnackBar(
          context,
          'Войдите в аккаунт для доступа к календарю',
          true,
        );
        Navigator.of(context).pop();
      });
    }
  }

  Future<void> _loadWorkouts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('user_calendar').doc(user.uid).get();
      if (doc.exists && doc.data()?['workouts'] != null) {
        setState(() {
          _workouts = Map<String, dynamic>.from(doc.data()!['workouts']);
          _calculateStreak();
        });
      }
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка загрузки тренировок: $e', true);
    }
  }

  Future<void> _calculateStreak() async {
    final now = DateTime.now();
    int streak = 0;
    DateTime currentDate = now;

    while (true) {
      final dateKey = '${currentDate.year}-${currentDate.month}-${currentDate.day}';
      final workout = _workouts[dateKey];

      if (workout == null || workout['completed'] != true) {
        break;
      }

      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    setState(() {
      _streakDays = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final today = DateTime.now();
    final isToday = (date) =>
        date.year == today.year && date.month == today.month && date.day == today.day;

    return Scaffold(
      body: Stack(
        children: [
          // Фоновое изображение
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/background.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Контент календаря
          SafeArea(
            child: Column(
              children: [
                // Кнопка "Назад"
                // Padding(
                //   padding: const EdgeInsets.all(16.0),
                //   child: Align(
                //     alignment: Alignment.topLeft,
                //     child: IconButton(
                //       icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                //       onPressed: () => Navigator.of(context).pop(),
                //     ),
                //   ),
                // ),
                // Отступ для опускания календаря
                const SizedBox(height: 100),
                // Календарь с прозрачным фоном
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // Прозрачный белый фон
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
                  child: Column(
                    children: [
                      // Месяц и год
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Заголовки дней недели
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Text('Пн', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Вт', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Ср', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Чт', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Пт', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Сб', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('Вс', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Кнопки навигации по месяцам и "Сегодня"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime(
                                      _selectedDate.year, _selectedDate.month - 1, 1);
                                });
                              },
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime.now();
                                });
                              },
                              child: const Text('Сегодня', style: TextStyle(fontSize: 12)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = DateTime(
                                      _selectedDate.year, _selectedDate.month + 1, 1);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      // Календарь
                      SizedBox(
                        height: 300, // Уменьшенная высота календаря
                        child: GridView.builder(
                          padding: const EdgeInsets.all(4),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                          itemCount: _getDaysInMonth(_selectedDate) + _getFirstWeekday(_selectedDate),
                          itemBuilder: (context, index) {
                            if (index < _getFirstWeekday(_selectedDate)) {
                              return const SizedBox.shrink();
                            }

                            final day = index - _getFirstWeekday(_selectedDate) + 1;
                            final currentDate = DateTime(_selectedDate.year, _selectedDate.month, day);
                            final dateKey = '${currentDate.year}-${currentDate.month}-${currentDate.day}';
                            final workout = _workouts[dateKey];
                            final hasWorkout = workout != null;
                            final isCompleted = workout?['completed'] == true;

                            return GestureDetector(
                              onTap: () => _showWorkoutDialog(currentDate),
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isToday(currentDate)
                                      ? primaryColor
                                      : hasWorkout
                                          ? isCompleted
                                              ? Colors.green[100]
                                              : Colors.grey[50]
                                          : null,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    day.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isToday(currentDate)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isToday(currentDate)
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),// Сердечко и количество дней
                if (_streakDays > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Количество дней без пропуска: $_streakDays',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                            const Icon(Icons.favorite, color: Colors.red, size: 20),
                          ],
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

  String _getMonthName(int month) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month - 1];
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstWeekday(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday - 1;
  }

  void _showWorkoutDialog(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    final existingWorkout = _workouts[dateKey];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${date.day}.${date.month}.${date.year}', style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Выполнил тренировку', style: TextStyle(fontSize: 14)),
              tileColor: existingWorkout?['completed'] == true ? Colors.green[100] : null,
              onTap: () {
                _saveWorkout(date, true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Не выполнил тренировку', style: TextStyle(fontSize: 14)),
              tileColor: existingWorkout?['completed'] == false ? Colors.grey[50] : null,
              onTap: () {
                _saveWorkout(date, false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Очистить', style: TextStyle(fontSize: 14)),
              tileColor: existingWorkout == null ? Colors.grey[100] : null,
              onTap: () {
                _clearWorkout(date);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWorkout(DateTime date, bool completed) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final dateKey = '${date.year}-${date.month}-${date.day}';
    setState(() {
      _workouts[dateKey] = {
        'completed': completed,
        'date': FieldValue.serverTimestamp(),
      };
    });

    try {
      await _firestore.collection('user_calendar').doc(user.uid).set({
        'workouts': _workouts,
      }, SetOptions(merge: true));
      await _calculateStreak();
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка сохранения тренировки: $e', true);
    }
  }

  Future<void> _clearWorkout(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final dateKey = '${date.year}-${date.month}-${date.day}';
    setState(() {
      _workouts.remove(dateKey);
    });

    try {
      await _firestore.collection('user_calendar').doc(user.uid).set({
        'workouts': _workouts,
      }, SetOptions(merge: true));
      await _calculateStreak();
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка очистки тренировки: $e', true);
    }
  }
}