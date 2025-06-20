import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/snackbar.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      _loadCalendarData();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SnackBarService.showSnackBar(
            context,
            'Войдите в аккаунт для доступа к календарю',
            true,
          );
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _loadCalendarData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Load calendar workout markers
      final calendarDoc =
      await _firestore.collection('user_calendar').doc(user.uid).get();
      if (calendarDoc.exists && calendarDoc.data()?['workouts'] != null) {
        if (mounted) {
          setState(() {
            _workouts =
            Map<String, dynamic>.from(calendarDoc.data()!['workouts']);
          });
        }
      }

      // Load user data for streak
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        if (mounted) {
          setState(() {
            _streakDays = userDoc.data()?['streakDays'] ?? 0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarService.showSnackBar(
            context, 'Ошибка загрузки данных: $e', true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _recalculateAndSaveStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Получаем все даты выполненных тренировок
    final completedDates = _workouts.entries
        .where((entry) =>
    (entry.value is Map) && entry.value['completed'] == true)
        .map((entry) {
      try {
        final parts = entry.key.split('-');
        return DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      } catch (e) {
        return null;
      }
    }).where((date) => date != null)
        .cast<DateTime>()
        .toList();

    // 2. Сортируем даты от самой новой к самой старой
    completedDates.sort((a, b) => b.compareTo(a));

    int calculatedStreak = 0;

    // 3. Считаем стрик
    if (completedDates.isNotEmpty) {
      DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      // Стрик может начаться только если тренировка была сегодня или вчера и сегодня нет тренировки
      // Проверяем, была ли тренировка сегодня
      if (completedDates.first.isAtSameMomentAs(today)) {
        calculatedStreak = 1;
        // Идем по списку и ищем последовательные дни
        for (int i = 0; i < completedDates.length - 1; i++) {
          // Проверяем, что разница между текущим днем и следующим ровно 1 день
          if (completedDates[i].difference(completedDates[i + 1]).inDays == 1) {
            calculatedStreak++;
          } else {
            // Если разрыв больше, стрик прерван
            break;
          }
        }
      } else if (completedDates.first.difference(today).inDays == -1) { // Если последняя тренировка была вчера
        calculatedStreak = 1; // Стрик начинается со вчерашнего дня
        for (int i = 0; i < completedDates.length - 1; i++) {
          if (completedDates[i].difference(completedDates[i + 1]).inDays == 1) {
            calculatedStreak++;
          } else {
            break;
          }
        }
      }
    }


    // 4. Сохраняем результат в Firestore и обновляем состояние
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'streakDays': calculatedStreak});
      if (mounted) {
        setState(() {
          _streakDays = calculatedStreak;
        });
      }
    } catch (e) {
      debugPrint("Error saving recalculated streak: $e");
    }
  }


  Future<void> _updateWorkoutStatus(DateTime date, bool completed) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final dateKey = '${date.year}-${date.month}-${date.day}';

    // Оптимистичное обновление UI
    setState(() {
      if (completed) {
        _workouts[dateKey] = {
          'completed': true,
          'date': Timestamp.fromDate(date),
        };
      } else {
        // Удаляем запись, если тренировка не выполнена (или отменена)
        _workouts.remove(dateKey);
      }
    });

    try {
      // Сохраняем изменение в календаре
      await _firestore.collection('user_calendar').doc(user.uid).set({
        'workouts': _workouts,
      }, SetOptions(merge: true));

      // Пересчитываем и сохраняем стрик
      await _recalculateAndSaveStreak();

    } catch (e) {
      if (mounted) {
        SnackBarService.showSnackBar(
            context, 'Ошибка сохранения тренировки: $e', true);
        // В случае ошибки откатываем изменения в UI
        await _loadCalendarData();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Пожалуйста, войдите в аккаунт.")),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final today = DateTime.now();
    final isToday = (date) =>
    date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

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
                const SizedBox(height: 100),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Column(
                    children: [
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Text('Пн',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text('Вт',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text('Ср',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text('Чт',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text('Пт',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text('Сб',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text('Вс',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  _selectedDate = DateTime(_selectedDate.year,
                                      _selectedDate.month - 1, 1);
                                });
                              },
                            ),
                            TextButton(
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  _selectedDate = DateTime.now();
                                });
                              },
                              child: const Text('Сегодня',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  _selectedDate = DateTime(_selectedDate.year,
                                      _selectedDate.month + 1, 1);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 300,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(4),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                          itemCount: _getDaysInMonth(_selectedDate) +
                              _getFirstWeekday(_selectedDate),
                          itemBuilder: (context, index) {
                            if (index < _getFirstWeekday(_selectedDate)) {
                              return const SizedBox.shrink();
                            }

                            final day =
                                index - _getFirstWeekday(_selectedDate) + 1;
                            final currentDate = DateTime(
                                _selectedDate.year, _selectedDate.month, day);
                            final dateKey =
                                '${currentDate.year}-${currentDate.month}-${currentDate.day}';
                            final workout = _workouts[dateKey];
                            final isCompleted =
                                workout?['completed'] == true;

                            return Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isToday(currentDate)
                                    ? primaryColor
                                    : isCompleted
                                    ? Colors.green[100]
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_streakDays > 0)
                  Padding(
                    padding:
                    const EdgeInsets.only(right: 16.0, bottom: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Дней без пропуска: $_streakDays',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.favorite,
                                color: Colors.red, size: 20),
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
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];
    return months[month - 1];
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstWeekday(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday - 1;
  }
}