import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // Добавлен импорт url_launcher
import '../services/colors.dart';
import '../services/snackbar.dart';
import 'package:flowstate/pages/acc_page.dart';
import 'package:flowstate/pages/login_page.dart';
import 'package:flowstate/pages/calendar.dart';
import 'package:flowstate/pages/statistic.dart';
import 'package:flowstate/pages/joint_workouts_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- ГЛОБАЛЬНАЯ ФУНКЦИЯ ДЛЯ ВЫЗОВА ДИАЛОГА ПРИГЛАШЕНИЯ ---
Future<void> showInviteFriendDialog(
    BuildContext context,
    String workoutName,
    List<Map<String, dynamic>> exercises,
    ) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    SnackBarService.showSnackBar(context, 'Для приглашения нужно войти в аккаунт', true);
    return;
  }

  // Загрузка списка друзей
  final friendsSnapshot = await FirebaseFirestore.instance
      .collection('friends')
      .where('users', arrayContains: user.uid)
      .get();

  if (friendsSnapshot.docs.isEmpty && context.mounted) {
    SnackBarService.showSnackBar(context, 'У вас нет друзей для приглашения', true);
    return;
  }

  final List<Map<String, dynamic>> friends = [];
  for (var doc in friendsSnapshot.docs) {
    try {
      final friendId = doc.data()['users'].firstWhere((id) => id != user.uid);
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(friendId).get();
      if (userDoc.exists) {
        friends.add({'id': friendId, 'nickname': userDoc.data()?['nickname'] ?? 'Без имени'});
      }
    } catch (e) {
      debugPrint("Ошибка загрузки друга: $e");
    }
  }

  if (friends.isEmpty && context.mounted) {
    SnackBarService.showSnackBar(context, 'Не удалось загрузить список друзей.', true);
    return;
  }

  String? selectedFriendId;

  // Показываем диалог выбора друга
  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Пригласить друга'),
      content: DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: 'Выберите друга'),
        items: friends
            .map((friend) => DropdownMenuItem<String>(
          value: friend['id'],
          child: Text(friend['nickname']),
        ))
            .toList(),
        onChanged: (value) => selectedFriendId = value,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
        TextButton(
          onPressed: () async {
            if (selectedFriendId != null) {
              Navigator.pop(dialogContext); // Закрываем диалог выбора
              await _sendAndTrackInvitation(context, selectedFriendId!, workoutName, exercises);
            } else {
              SnackBarService.showSnackBar(context, 'Выберите друга', true);
            }
          },
          child: const Text('Пригласить'),
        ),
      ],
    ),
  );
}

// Внутренняя функция для отправки приглашения и отслеживания статуса
Future<void> _sendAndTrackInvitation(
    BuildContext context,
    String friendId,
    String workoutName,
    List<Map<String, dynamic>> exercises,
    ) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final sessionId = 'joint_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

  try {
    // 1. Создаем сессию и уведомление в Firestore
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    final sessionRef = FirebaseFirestore.instance.collection('joint_sessions').doc(sessionId);

    batch.set(sessionRef, {
      'hostId': user.uid,
      'invitedParticipantId': friendId,
      'participantId': null,
      'workoutName': workoutName,
      'exercises': exercises, // Передаем список упражнений
      'status': 'invited', // 'invited', 'active', 'rejected', 'cancelled', 'completed'
      'createdAt': FieldValue.serverTimestamp(),
      // Начальные состояния для тренировки
      'currentExerciseIndex': 0,
      'currentPage': 0,
      'isTimerRunning': false,
      'isPaused': true,
      'secondsRemaining': 30, // Значение по умолчанию
    });

    final notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
    batch.set(notificationRef, {
      'type': 'workout_invite',
      'fromUserId': user.uid,
      'toUserId': friendId,
      'sessionId': sessionId,
      'workoutName': workoutName,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'status': 'pending', // 'pending', 'delivered', 'accepted', 'rejected'
    });

    await batch.commit();

    if (!context.mounted) return;
    SnackBarService.showSnackBar(context, 'Приглашение отправлено!', false);

    // 2. Показываем диалог ожидания ответа
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _HostWaitingDialog(
        sessionId: sessionId,
        parentContext: context,
      ),
    );
  } catch (e) {
    if (context.mounted) {
      SnackBarService.showSnackBar(context, "Ошибка отправки приглашения: $e", true);
    }
  }
}

// --- ОСНОВНОЙ ВИДЖЕТ ЭКРАНА ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TrainingScreen(initialTabIndex: 0);
  }
}

class TrainingScreen extends StatefulWidget {
  final int initialTabIndex;

  const TrainingScreen({super.key, this.initialTabIndex = 0});

  @override
  TrainingScreenState createState() => TrainingScreenState();
}

class TrainingScreenState extends State<TrainingScreen> {
  late int _selectedIndex;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // Слушатель для входящих приглашений
  void _setupNotificationListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('type', isEqualTo: 'workout_invite')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        // Помечаем как "доставленное", чтобы диалог не появлялся повторно
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .update({'status': 'delivered'});

        final data = doc.data();
        if (mounted) {
          _showInvitationDialog(
            context,
            data['fromUserId'],
            data['sessionId'],
            data['workoutName'],
            doc.id,
          );
        }
      }
    });
  }

  // Диалог для получателя приглашения
  void _showInvitationDialog(
      BuildContext context,
      String fromUserId,
      String sessionId,
      String workoutName,
      String notificationId,
      ) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(fromUserId).get();
    final fromUserName = userDoc.data()?['nickname'] ?? 'Пользователь';

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Приглашение на тренировку'),
        content: Text('$fromUserName приглашает вас на тренировку: "$workoutName"'),
        actions: [
          TextButton(
            onPressed: () async {
              // Логика отклонения
              final WriteBatch batch = FirebaseFirestore.instance.batch();
              batch.update(FirebaseFirestore.instance.collection('notifications').doc(notificationId), {'status': 'rejected'});
              batch.update(FirebaseFirestore.instance.collection('joint_sessions').doc(sessionId), {'status': 'rejected'});
              await batch.commit();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Отклонить'),
          ),
          TextButton(
            onPressed: () async {
              // Логика принятия
              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;
                final WriteBatch batch = FirebaseFirestore.instance.batch();
                batch.update(FirebaseFirestore.instance.collection('notifications').doc(notificationId), {'status': 'accepted'});
                batch.update(FirebaseFirestore.instance.collection('joint_sessions').doc(sessionId), {
                  'status': 'active',
                  'participantId': currentUser.uid,
                });
                await batch.commit();

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(); // Сначала закрываем диалог
                  Navigator.push( // Затем переходим на экран
                    context,
                    MaterialPageRoute(
                      builder: (context) => JointWorkoutScreen(
                        sessionId: sessionId,
                        isHost: false, // Принявший не хост
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  SnackBarService.showSnackBar(dialogContext, 'Ошибка: $e', true);
                  Navigator.of(dialogContext).pop();
                }
              }
            },
            child: const Text('Принять'),
          ),
        ],
      ),
    );
  }

  // --- UI ЧАСТЬ ---
  static const List<Widget> _screens = [
    TrainingContent(),
    CalendarScreen(),
    StatsScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    final user = FirebaseAuth.instance.currentUser;

    if (index == 3 && user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 45.0, vertical: 40.0),
        child: SizedBox(
          height: 71.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: secondaryColor,
              selectedItemColor: activeIconColor,
              unselectedItemColor: inactiveIconColor,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              iconSize: 24.0,
              items: [
                BottomNavigationBarItem(icon: _buildNavIcon(Icons.home, 0), activeIcon: _buildActiveNavIcon(Icons.home), label: ''),
                BottomNavigationBarItem(icon: _buildNavIcon(Icons.calendar_today, 1), activeIcon: _buildActiveNavIcon(Icons.calendar_today), label: ''),
                BottomNavigationBarItem(icon: _buildNavIcon(Icons.group, 2), activeIcon: _buildActiveNavIcon(Icons.group), label: ''),
                BottomNavigationBarItem(icon: _buildNavIcon(Icons.person, 3), activeIcon: _buildActiveNavIcon(Icons.person), label: ''),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(color: Color.fromARGB(124, 236, 241, 229), shape: BoxShape.circle),
      child: Icon(icon, size: 24),
    );
  }

  Widget _buildActiveNavIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
      child: Icon(icon, size: 24),
    );
  }
}

class TrainingContent extends StatelessWidget {
  const TrainingContent({super.key});

  // Исправленная функция для открытия URL
  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка: Не удалось открыть ссылку', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Stack(
          children: [
            Positioned.fill(child: SvgPicture.asset('assets/background.svg', fit: BoxFit.cover)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (user == null) ...[
                    const Text('Вы не авторизованы', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 40),
                    _buildButton('ВОЙТИ', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()))),
                  ] else ...[
                    const SizedBox(height: 10),
                    // Новая кнопка "ПЕРЕЙТИ НА САЙТ"
                    _buildButton('ПОДДЕРЖАТЬ НАС', () => _launchURL(context, 'https://boosty.to/flow_state/donate')),
                    const SizedBox(height: 40),
                    _buildButton('УПРАЖНЕНИЯ', () => Navigator.pushNamed(context, '/exercises')),
                    const SizedBox(height: 40),
                    _buildButton('ГОТОВЫЕ ТРЕНИРОВКИ', () => Navigator.pushNamed(context, '/ready_workouts')),
                    const SizedBox(height: 40),
                    _buildButton('СОЗДАТЬ ТРЕНИРОВКУ', () => Navigator.pushNamed(context, '/create_workout')),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 300,
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }
}

// --- ВИДЖЕТ ДИАЛОГА ОЖИДАНИЯ ОТВЕТА ХОСТОМ ---
class _HostWaitingDialog extends StatefulWidget {
  final String sessionId;
  final BuildContext parentContext; // Контекст для навигации после успеха
  const _HostWaitingDialog({required this.sessionId, required this.parentContext});

  @override
  _HostWaitingDialogState createState() => _HostWaitingDialogState();
}

class _HostWaitingDialogState extends State<_HostWaitingDialog> {
  StreamSubscription? _sessionSubscription;
  String _status = 'invited';

  @override
  void initState() {
    super.initState();
    _subscribeToSessionStatus();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToSessionStatus() {
    _sessionSubscription = FirebaseFirestore.instance
        .collection('joint_sessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (!snapshot.exists) {
        Navigator.of(context).pop();
        return;
      }
      final newStatus = snapshot.data()?['status'] as String? ?? 'cancelled';
      if (_status != newStatus) {
        setState(() => _status = newStatus);

        // Автоматически обрабатываем конечные статусы
        if (newStatus == 'active') {
          // Закрываем диалог и переходим на экран тренировки
          Navigator.of(context).pop();
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(
              builder: (context) => JointWorkoutScreen(sessionId: widget.sessionId, isHost: true),
            ),
          );
        } else if (newStatus == 'rejected' || newStatus == 'cancelled') {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      }
    });
  }

  Future<void> _cancelInvitation() async {
    await FirebaseFirestore.instance
        .collection('joint_sessions')
        .doc(widget.sessionId)
        .update({'status': 'cancelled'});
  }

  Widget _buildContentForStatus() {
    switch (_status) {
      case 'rejected':
      case 'cancelled':
        return Column(
          key: const ValueKey('rejected'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 48),
            const SizedBox(height: 20),
            Text(_status == 'rejected' ? "Приглашение отклонено." : "Приглашение отменено."),
            const SizedBox(height: 10),
            const Text("Это окно закроется автоматически.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        );

      case 'invited':
      default:
        return Column(
          key: const ValueKey('waiting'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text("Ожидание ответа от друга..."),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _cancelInvitation,
              child: const Text("Отменить приглашение", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Запрещаем закрытие системной кнопкой
      child: AlertDialog(
        title: const Text("Статус приглашения"),
        content: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildContentForStatus(),
        ),
      ),
    );
  }
}