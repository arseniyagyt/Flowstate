import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/colors.dart';
import '../services/snackbar.dart';
import 'joint_workouts_screen.dart';

// --- ВИДЖЕТ ДИАЛОГА ОЖИДАНИЯ ОТВЕТА ХОСТОМ (ИСПРАВЛЕННАЯ ВЕРСИЯ) ---
// Логика приведена в соответствие с home_page.dart для консистентности
class _HostWaitingDialog extends StatefulWidget {
  final String sessionId;
  final BuildContext parentContext;

  const _HostWaitingDialog({
    required this.sessionId,
    required this.parentContext,
  });

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

        if (newStatus == 'active') {
          // Автоматический переход к тренировке при принятии
          Navigator.of(context).pop(); // Закрываем диалог
          Navigator.push(
            widget.parentContext,
            MaterialPageRoute(
              builder: (context) => JointWorkoutScreen(sessionId: widget.sessionId, isHost: true),
            ),
          );
        } else if (newStatus == 'rejected' || newStatus == 'cancelled') {
          // Автоматическое закрытие диалога через 3 секунды
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
    // Диалог закроется автоматически благодаря StreamSubscription
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
      onWillPop: () async => false, // Запрет закрытия системной кнопкой "назад"
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

// --- ОСНОВНОЙ ЭКРАН УПРАЖНЕНИЙ (С ИСПРАВЛЕНИЯМИ) ---
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  // Выносим данные в список для легкого доступа
  static final List<Map<String, String>> _allExercises = [
    {'name': 'Анантасана', 'image1': 'assets/Anantasana_1.svg', 'image2': 'assets/Anantasana_2.svg', 'image3': 'assets/Anantasana_3.svg'},
    {'name': 'Бхуджангасана', 'image1': 'assets/Bhujangasana_1.svg', 'image2': 'assets/Bhujangasana_2.svg', 'image3': 'assets/Bhujangasana_3.svg'},
    {'name': 'Маха Мудра', 'image1': 'assets/MahaMudra_1.svg', 'image2': 'assets/MahaMudra_2.svg', 'image3': 'assets/MahaMudra_3.svg'},
    {'name': 'Паригхасана', 'image1': 'assets/Parigkhasana_1.svg', 'image2': 'assets/Parigkhasana_2.svg', 'image3': 'assets/Parigkhasana_3.svg'},
    {'name': 'Триконасана', 'image1': 'assets/Trikonasana_1.svg', 'image2': 'assets/Trikonasana_2.svg', 'image3': 'assets/Trikonasana_3.svg'},
    {'name': 'Пашчимоттанасана', 'image1': 'assets/idk_1.svg', 'image2': 'assets/idk_2.svg', 'image3': 'assets/idk_3.svg'},
    {'name': 'Баласана', 'image1': 'assets/Balasana_1.svg', 'image2': 'assets/Balasana_2.svg', 'image3': 'assets/Balasana_3.svg'},
    {'name': 'Падмасана', 'image1': 'assets/Padmasana_1.svg', 'image2': 'assets/Padmasana_2.svg', 'image3': 'assets/Padmasana_3.svg'},
    {'name': 'Супта Вирасана', 'image1': 'assets/SuptaVirasana_1.svg', 'image2': 'assets/SuptaVirasana_2.svg', 'image3': 'assets/SuptaVirasana_3.svg'},
    {'name': 'Шавасана', 'image1': 'assets/Shavasana_1.svg', 'image2': 'assets/Shavasana_1.svg', 'image3': 'assets/Shavasana_1.svg'},
    {'name': 'Супта Свастикасана', 'image1': 'assets/SuptaSvastikasana_1.svg', 'image2': 'assets/SuptaSvastikasana_2.svg', 'image3': 'assets/SuptaSvastikasana_2.svg'},
  ];

  // --- ИСПРАВЛЕННАЯ ЛОГИКА ПРИГЛАШЕНИЯ ---

  Future<void> _showInviteDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      SnackBarService.showSnackBar(context, 'Для приглашения нужно войти в аккаунт', true);
      return;
    }

    final friends = await _loadFriends(user.uid);
    if (friends.isEmpty && context.mounted) {
      SnackBarService.showSnackBar(context, 'У вас нет друзей для совместной тренировки', true);
      return;
    }

    String? selectedExerciseName;
    String? selectedFriendId;

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Пригласить друга'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Выберите упражнение'),
              items: _allExercises
                  .map((exercise) => DropdownMenuItem<String>(value: exercise['name'], child: Text(exercise['name']!)))
                  .toList(),
              onChanged: (value) => selectedExerciseName = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Выберите друга'),
              items: friends
                  .map((friend) => DropdownMenuItem<String>(value: friend['id'], child: Text(friend['nickname'] ?? 'Без ника')))
                  .toList(),
              onChanged: (value) => selectedFriendId = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              if (selectedExerciseName != null && selectedFriendId != null) {
                Navigator.pop(dialogContext); // Закрываем диалог выбора
                await _sendAndTrackInvitation(context, selectedFriendId!, selectedExerciseName!);
              } else {
                SnackBarService.showSnackBar(context, 'Выберите друга и упражнение', true);
              }
            },
            child: const Text('Пригласить'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendAndTrackInvitation(BuildContext context, String friendId, String exerciseName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Находим полные данные о выбранном упражнении
    final exerciseData = _allExercises.firstWhere((ex) => ex['name'] == exerciseName, orElse: () => {});
    if (exerciseData.isEmpty) {
      if(context.mounted) SnackBarService.showSnackBar(context, "Ошибка: упражнение не найдено", true);
      return;
    }

    // Создаем "тренировку" из одного упражнения, чтобы соответствовать формату
    final List<Map<String, dynamic>> exercisesList = [
      {
        'name': exerciseData['name'],
        'image1': exerciseData['image1'],
        'image2': exerciseData['image2'],
        'image3': exerciseData['image3'],
      }
    ];

    final sessionId = 'joint_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // Отправляем приглашение с унифицированными данными
      await _sendInvitation(user.uid, friendId, sessionId, exerciseName, exercisesList);
      if (!context.mounted) return;
      SnackBarService.showSnackBar(context, 'Приглашение отправлено!', false);

      // Показываем диалог ожидания
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

  // Функция приведена в полное соответствие с home_page.dart
  Future<void> _sendInvitation(String hostId, String friendId, String sessionId, String workoutName, List<Map<String, dynamic>> exercises) async {
    final WriteBatch batch = FirebaseFirestore.instance.batch();

    // 1. Документ сессии
    final sessionRef = FirebaseFirestore.instance.collection('joint_sessions').doc(sessionId);
    batch.set(sessionRef, {
      'hostId': hostId,
      'invitedParticipantId': friendId,
      'participantId': null,
      'workoutName': workoutName, // Правильное поле
      'exercises': exercises,      // Правильное поле
      'status': 'invited',
      'createdAt': FieldValue.serverTimestamp(),
      'currentExerciseIndex': 0,
      'currentPage': 0,
      'isTimerRunning': false,
      'isPaused': true,
      'secondsRemaining': 30,
    });

    // 2. Документ уведомления
    final notificationRef = FirebaseFirestore.instance.collection('notifications').doc();
    batch.set(notificationRef, {
      'type': 'workout_invite',
      'fromUserId': hostId,
      'toUserId': friendId,
      'sessionId': sessionId,
      'workoutName': workoutName, // Правильное поле
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'status': 'pending',
    });

    await batch.commit();
  }


  // --- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ И UI (без изменений) ---

  Future<List<Map<String, dynamic>>> _loadFriends(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('friends').where('users', arrayContains: userId).get();
      if (snapshot.docs.isEmpty) return [];

      final List<Future<Map<String, dynamic>?>> friendFutures = snapshot.docs.map((doc) async {
        try {
          final friendId = doc.data()['users'].firstWhere((id) => id != userId);
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(friendId).get();
          if (userDoc.exists) {
            return {...userDoc.data()!, 'id': friendId};
          }
          return null;
        } catch (e) {
          debugPrint("Ошибка загрузки друга: $e");
          return null;
        }
      }).toList();

      final results = await Future.wait(friendFutures);
      return results.whereType<Map<String, dynamic>>().toList();

    } catch (e) {
      debugPrint("Ошибка загрузки списка друзей: $e");
      return [];
    }
  }

  Widget _buildExerciseCard(BuildContext context, Map<String, String> exerciseData) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ExerciseDetailScreen(
          exerciseName: exerciseData['name']!,
          imagePath1: exerciseData['image1']!,
          imagePath2: exerciseData['image2']!,
          imagePath3: exerciseData['image3']!
      ))),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF92A880), width: 4),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SvgPicture.asset(exerciseData['image1']!, width: 120, height: 120, fit: BoxFit.fitWidth),
            ),
            const SizedBox(height: 8),
            Text(exerciseData['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center, ),
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
          Positioned.fill(child: SvgPicture.asset('assets/background.svg', fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    IconButton(icon: const Icon(Icons.arrow_back, size: 30), onPressed: () => Navigator.pop(context)),
                    const Expanded(child: Text("Упражнения", textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 48), // Для симметрии
                  ]),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _allExercises.length,
                    itemBuilder: (context, index) {
                      return _buildExerciseCard(context, _allExercises[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInviteDialog(context),
        backgroundColor: const Color(0xFF92A880),
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }
}


// ===========================================================================
// ExerciseDetailScreen - ЭТА ЧАСТЬ ОСТАЕТСЯ БЕЗ ИЗМЕНЕНИЙ
// ===========================================================================

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseName;
  final String imagePath1;
  final String imagePath2;
  final String imagePath3;

  const ExerciseDetailScreen({
    required this.exerciseName,
    required this.imagePath1,
    required this.imagePath2,
    required this.imagePath3,
    super.key,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late PageController pageController;
  int currentPage = 0;
  Timer? timer;
  int timerDuration = 30;
  bool isTimerRunning = false;
  bool showPraise = false;
  late FlutterTts flutterTts;
  late AudioPlayer audioPlayer;
  double _voiceVolume = 50.0;
  String? _selectedVoice;
  double _musicVolume = 50.0;
  String? _selectedMusicTrack;

  final Map<String, List<String>> exerciseInstructions = {
    'Анантасана': [
      '<speak>Позиция 1: Лягте на спину. Расслабьтесь, почувствуйте контакт тела с полом. На выдохе плавно перекатитесь на левый бок. Расположитесь так, чтобы вес тела равномерно распределился на левом боку. Теперь аккуратно приподнимите голову. Левую руку вытяните над головой, выстраивая одну линию с телом. Согните локоть и ладонью левой руки мягко поддержите голову — расположите её чуть выше уха. Дышите спокойно или сделайте 2–3 глубоких цикла дыхания.</speak>',
      '<speak>Позиция 2: Согните правое колено. Правой рукой обхватите большой палец правой ноги: большой, указательный и средний пальцы плотно фиксируют стопу.<break time="500ms"/> На выдохе медленно выпрямите правую ногу и руку, поднимая их вертикально вверх. Представьте, как энергия от стопы тянется к кончикам пальцев.</speak>',
      '<speak>Позиция 3: Удерживайте позу 15–20 секунд. Дышите ровно, сохраняя контроль над положением тела. На выдохе так же плавно согните колено и вернитесь в положение на боку. Не торопитесь — движение должно быть осознанным.<break time="500ms"/> Осторожно опустите голову с ладони и перекатитесь обратно на спину. Дайте себе момент отдыха.<break time="500ms"/> Теперь повторите всё в другую сторону: перекатитесь на правый бок, выполните те же шаги с левой ногой и рукой. Следите за симметрией — время удержания должно быть одинаковым для обеих сторон.<break time="500ms"/> После завершения асаны останьтесь на спине. Почувствуйте, как тело наполняется лёгкостью, а мышцы мягко расслабляются.</speak>',
    ],
    'Бхуджангасана': [
      '<speak>Позиция 1: Лягте на живот<break time="500ms"/> ладони под плечами.</speak>',
      '<speak>Позиция 2: Поднимите грудь вверх<break time="500ms"/> вытягивая позвоночник.</speak>',
      '<speak>Позиция 3: Удерживайте позу<break time="500ms"/> дышите ровно.</speak>',
    ],
    'Маха Мудра': [
      '<speak>Позиция 1: Сядьте на пол, вытяните ноги перед собой. Почувствуйте, как копчик тянется к полу, а макушка — к потолку.</speak>',
      '<speak>Позиция 2: Теперь согните левое колено и аккуратно опустите его влево. Внешняя часть левого бедра и голени должна полностью касаться пола. Представьте, будто левая нога образует полукруг — плавный, как крыло птицы. Расположите левую пятку у внутренней поверхности левого бедра, близко к промежности. Большой палец левой стопы мягко прижмите к правому бедру. Проверьте угол между ногами: вытянутая правая и согнутая левая должны создать чёткие 90 градусов.<break time="500ms"/> На вдохе вытяните руки вперед, к правой стопе.</speak>',
      '<speak>Позиция 3: Обхватите большой палец правой ноги большим и указательным пальцами обеих рук. Если гибкость позволяет, захватите стопу полностью.<break time="500ms"/> Медленно опустите подбородок к грудине, словно пытаетесь удержать им персиковую косточку. Шея расслаблена, макушка продолжает тянуться вперед.<break time="500ms"/> Спокойный выдох.<break time="500ms"/> Следите за позвоночником: он должен оставаться вытянутым, как струна. Правая нога неподвижна — не позволяйте ей смещаться в сторону.<break time="500ms"/> Акцент: «Вообразите, что ваша спина прижата к невидимой стене».<break time="500ms"/> Сделайте глубокий вдох. Напрягите мышцы живота, подтягивая их от нижней части к диафрагме. Зафиксируйте это напряжение.<break time="1000ms"/> На выдохе расслабьте живот. Снова вдохните, задержите дыхание и сохраняйте напряжение. Удерживайте позу от 1 до 3 минут, сохраняя ровный ритм дыхания.</speak>',
    ],
    'Паригхасана': [
      '<speak>Позиция 1: Встаньте на колени, соединив лодыжки. Почувствуйте, как вес тела равномерно распределяется между бёдрами и голенями. Медленно вытяните правую ногу вправо. Стопу разверните в ту же сторону, будто рисуете пяткой линию на полу. Держите ногу прямой — представьте, что она продолжает линию вашего корпуса и левого колена. Проверьте: плечи остаются над бёдрами, макушка тянется вверх. На вдохе раскройте руки в стороны, как крылья птицы. Ладони направьте вниз, пальцы слегка разведите. Сделайте два глубоких цикла дыхания, чтобы настроиться.</speak>',
      '<speak>Позиция 2: На выдохе плавно наклоните корпус и правую руку к вытянутой ноге. Опустите правое предплечье на голень, а ладонь разместите на лодыжке внутренней стороной вверх. Расслабьте шею — правое ухо мягко ляжет на плечо. Представьте, будто ваша рука обвивает ногу, как лоза ствол дерева. Левую руку вытяните над головой, стараясь дотянуться ладонью до правой.</speak>',
      '<speak>Позиция 3: Левое ухо прижмите к верхней части левой руки, сохраняя шею расслабленной. Взгляд можно направить в потолок или закрыть глаза. Не форсируйте растяжку — пусть тело раскрывается постепенно.<break time="500ms"/> Удерживайте позу 30–60 секунд. Дышите ровно, представляя, как каждый выдох углубляет растяжение боковой поверхности тела.<break time="500ms"/> Фоновая пауза 3–4 секунды.<break time="3500ms"/> На вдохе медленно верните корпус в вертикальное положение, снова раскрыв руки в стороны. Согните правую ногу и мягко вернитесь в исходную позу на коленях. Двигайтесь так, будто вас поднимает невидимая нить за макушку. Повторите асану влево.</speak>',
    ],
    'Триконасана': [
      '<speak>Позиция 1: Начните с позы Тадасана — горы. Стойте прямо, сохраняя осанку. Сделайте глубокий вдох и мягким прыжком расставьте стопы на ширину 90–105 см. Поднимите руки в стороны на уровень плеч, ладони направьте вниз. Держите их параллельно полу, словно ваши пальцы тянутся к горизонту.</speak>',
      '<speak>Позиция 2: Теперь разверните правую стопу на 90 градусов вправо. Левую стопу слегка поверните в ту же сторону, сохраняя левую ногу прямой. Напрягите колени, чувствуя стабильность в ногах. Медленный выдох. На выдохе плавно наклоните корпус вправо. Опустите правую ладонь к правой лодыжке. Если позволяет гибкость, аккуратно разместите ладонь полностью на полу.</speak>',
      '<speak>Позиция 3: Левую руку вытяните вверх, продолжая линию правого плеча. Представьте, что макушка и левая ладонь тянутся в противоположные стороны. Следите, чтобы спина, таз и задняя поверхность ног оставались в одной плоскости. Взгляд мягко направьте на большой палец поднятой руки.<break time="500ms"/> Спокойный вдох-выдох.<break time="500ms"/> Проконтролируйте положение правого колена: оно должно быть зафиксировано, а коленная чашечка подтянута вверх. Колено направлено точно в сторону пальцев правой ноги.<break time="500ms"/> Пауза.<break time="500ms"/> Удерживайте позу от 30 секунд до минуты. Дышите ровно и глубоко, чувствуя растяжение боковой поверхности тела. На вдохе медленно поднимите правую ладонь с пола и вернитесь в исходное положение с раскинутыми руками. Повторите все то же самое в левую сторону.</speak>',
    ],
    'Пашчимоттанасана': [
      '<speak>Позиция 1: Сядьте<break time="500ms"/> вытяните ноги вперед.</speak>',
      '<speak>Позиция 2: Наклонитесь к ногам<break time="500ms"/> стараясь коснуться стоп.</speak>',
      '<speak>Позиция 3: Удерживайте наклон<break time="500ms"/> дышите глубоко.</speak>',
    ],
    'Баласана': [
      '<speak>Позиция 1: Сядьте на пятки<break time="500ms"/> колени вместе.</speak>',
      '<speak>Позиция 2: Наклонитесь вперед<break time="500ms"/> лоб к полу.</speak>',
      '<speak>Позиция 3: Расслабьтесь<break time="500ms"/> дышите ровно.</speak>',
    ],
    'Падмасана': [
      '<speak>Позиция 1: Сядьте<break time="500ms"/> скрестите ноги<break time="500ms"/> стопы на бедрах.</speak>',
      '<speak>Позиция 2: Выпрямите спину<break time="500ms"/> руки на коленях.</speak>',
      '<speak>Позиция 3: Удерживайте позу<break time="500ms"/> сосредоточьтесь на дыхании.</speak>',
    ],
    'Супта Вирасана': [
      '<speak>Позиция 1: Сядьте в позу Героя: опустите ягодицы между пяток, колени держите вместе. Если чувствуете дискомфорт — разведите бёдра чуть шире или подложите подушку.<break time="2000ms"/> На выдохе медленно отклоните корпус назад. Опускайтесь аккуратно, как будто ложитесь на невидимую волну. Сначала коснитесь пола локтями, один за другим.</speak>',
      '<speak>Позиция 2: Перенесите вес с локтей, вытягивая руки вдоль тела. Представьте, что ваши пальцы тянутся к пяткам.<break time="4000ms"/> Сделайте 2–3 глубоких вдоха, готовясь к следующему шагу.<break time="6000ms"/> Теперь опустите на пол верхнюю часть головы, как будто рисуете макушкой полукруг. Постепенно опускайте затылок, а затем и всю спину — позвонок за позвонком.<break time="7000ms"/> Следите, чтобы шея не перенапрягалась — движение должно быть плавным, как падение пера.</speak>',
      '<speak>Позиция 3: Когда спина полностью коснётся пола, вытяните руки за голову.<break time="3000ms"/> Ладони направьте в потолок, сохраняя лопатки прижатыми к полу.<break time="2000ms"/> Дышите глубоко, представляя, как воздух наполняет пространство между рёбер.<break time="3000ms"/> Удерживайте положение столько, сколько комфортно.<break time="20000ms"/> Для выхода: Медленно согните руки и поставьте локти по бокам корпуса. На выдохе, отталкиваясь от пола, вернитесь в сидячее положение. Двигайтесь медленнее, чем вам кажется нужным — позвольте мышцам включиться постепенно.<break time="5000ms"/> Разрешите коленям быть на ширине бёдер — это снимет нагрузку с поясницы. Завершите практику лёгким покачиванием тазом из стороны в сторону, чтобы снять напряжение.</speak>',
    ],
    'Шавасана': [
      '<speak>Позиция 1: Лягте на спину<break time="500ms"/> руки вдоль тела.</speak>',
      '<speak>Позиция 2: Расслабьте все мышцы<break time="500ms"/> дышите спокойно.</speak>',
      '<speak>Позиция 3: Полностью расслабьтесь<break time="500ms"/> сосредоточьтесь на дыхании.</speak>',
    ],
    'Супта Свастикасана': [
      '<speak>Позиция 1: Лягте на спину<break time="500ms"/> расслабьтесь.</speak>',
      '<speak>Позиция 2: Скрестите ноги в позе Свастикасаны<break time="500ms"/> удерживайте положение.</speak>',
      '<speak>Позиция 3: Расслабьтесь полностью<break time="500ms"/> дышите глубоко.</speak>',
    ],
  };

  final Map<String, List<int>> exerciseTimers = {
    'Анантасана': [30, 20, 40],
    'Бхуджангасана': [20, 30, 30],
    'Маха Мудра': [30, 30, 90],
    'Паригхасана': [30, 30, 60],
    'Триконасана': [30, 30, 60],
    'Пашчимоттанасана': [20, 30, 40],
    'Баласана': [20, 20, 30],
    'Падмасана': [30, 20, 60],
    'Супта Вирасана': [30, 60, 90],
    'Шавасана': [30, 30, 60],
    'Супта Свастикасана': [30, 30, 60],
  };

  final List<Map<String, String>> _availableMusicTracks = [
    {'id': 'ambient1', 'name': 'Спокойный эмбиент', 'path': 'assets/music/ambient1.mp3'},
    {'id': 'ambient2', 'name': 'Мягкий эмбиент', 'path': 'assets/music/ambient2.mp3'},
    {'id': 'nature', 'name': 'Звуки природы', 'path': 'assets/music/nature.mp3'},
    {'id': 'meditation', 'name': 'Медитация', 'path': 'assets/music/meditation.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    flutterTts = FlutterTts();
    audioPlayer = AudioPlayer();
    _loadSettings();
    _initTts();
  }

  Future<void> _updateWorkoutCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("Пользователь не авторизован, обновление отменено.");
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = '${today.year}-${today.month}-${today.day}';

    try {
      final userCalendarRef = firestore.collection('user_calendar').doc(user.uid);
      final userRef = firestore.collection('users').doc(user.uid);

      await firestore.runTransaction((transaction) async {
        final calendarDoc = await transaction.get(userCalendarRef);
        if (calendarDoc.exists && (calendarDoc.data()?['workouts']?[todayKey]?['completed'] == true)) {
          debugPrint("Тренировка на сегодня уже засчитана. Обновление не требуется.");
          return;
        }

        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          debugPrint("Документ пользователя не найден.");
          return;
        }

        final data = userDoc.data() ?? {};
        final lastWorkoutStamp = data['lastWorkoutDate'] as Timestamp?;
        final streakDays = data['streakDays'] ?? 0;
        final lastWorkoutDate = lastWorkoutStamp?.toDate();

        int newStreak = 1;
        if (lastWorkoutDate != null) {
          final yesterday = today.subtract(const Duration(days: 1));
          if (DateTime(lastWorkoutDate.year, lastWorkoutDate.month, lastWorkoutDate.day)
              .isAtSameMomentAs(yesterday)) {
            newStreak = streakDays + 1;
          }
        }

        transaction.update(userRef, {
          'lastWorkoutDate': Timestamp.fromDate(now),
          'streakDays': newStreak,
          'workoutHistory': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
        });

        transaction.set(
            userCalendarRef,
            {
              'workouts': {
                todayKey: {
                  'completed': true,
                  'date': Timestamp.fromDate(now),
                }
              }
            },
            SetOptions(merge: true));
      });

      debugPrint("Данные тренировки и стрик успешно обновлены!");

    } catch (e) {
      debugPrint('Ошибка атомарного обновления данных тренировки: $e');
      if (mounted) {
        SnackBarService.showSnackBar(
            context, 'Ошибка обновления данных тренировки', true);
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceVolume = prefs.getDouble('voiceVolume') ?? 50.0;
      _selectedVoice = prefs.getString('selectedVoice');
      _musicVolume = prefs.getDouble('musicVolume') ?? 50.0;
      _selectedMusicTrack = prefs.getString('selectedMusicTrack') ?? _availableMusicTracks[0]['id'];
    });
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ru-RU");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(_voiceVolume / 100);
    await flutterTts.setPitch(1.0);
    if (_selectedVoice != null) {
      await flutterTts.setVoice({"name": "$_selectedVoice", "locale": "ru-RU"});
    }
  }

  Future<void> _speakPosition(int page) async {
    final instructions = exerciseInstructions[widget.exerciseName] ?? ['<speak>Позиция ${page + 1}</speak>'];
    String text = instructions[page];

    await flutterTts.stop();

    try {
      await flutterTts.speak(text);
    } catch (e) {
      final fallbackText = text
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll(RegExp(r'<break time="[^"]*"/>'), ', ');
      await flutterTts.speak(fallbackText);
    }
  }

  Future<void> _playMusic() async {
    if (_selectedMusicTrack != null) {
      try {
        final track = _availableMusicTracks.firstWhere((t) => t['id'] == _selectedMusicTrack);
        await audioPlayer.setVolume(_musicVolume / 100);
        await audioPlayer.play(AssetSource(track['path']!.replaceFirst('assets/', '')), mode: PlayerMode.mediaPlayer);
        await audioPlayer.setReleaseMode(ReleaseMode.loop);
      } catch (e) {
        debugPrint('Ошибка воспроизведения музыки: $e');
      }
    }
  }

  Future<void> _stopMusic() async {
    try {
      await audioPlayer.stop();
    } catch (e) {
      debugPrint('Ошибка остановки музыки: $e');
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    timer?.cancel();
    flutterTts.stop();
    _stopMusic();
    audioPlayer.dispose();
    super.dispose();
  }

  void startTimer() {
    if (!mounted) return;
    setState(() {
      isTimerRunning = true;
      timerDuration = exerciseTimers[widget.exerciseName]![currentPage];
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (timerDuration > 0) {
          timerDuration--;
        } else {
          timer.cancel();
          isTimerRunning = false;
          if (currentPage < 2) {
            pageController.jumpToPage(currentPage + 1);
          } else {
            setState(() {
              showPraise = true;
              _updateWorkoutCompletion();
              _stopMusic();
            });
          }
        }
      });
    });
  }

  void _showFiveSecondAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Таймер запустится через 5 секунд'),
        duration: Duration(seconds: 5),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () async {
      if (mounted) {
        await _playMusic();
        _speakPosition(currentPage);
        startTimer();
      }
    });
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
                Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                        child: Text(
                          widget.exerciseName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      left: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 30,
                        ),
                        onPressed: () {
                          _stopMusic();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
                if (!showPraise)
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (int page) {
                        if (!mounted) return;
                        setState(() {
                          currentPage = page;
                          isTimerRunning = false;
                          timer?.cancel();
                          if (page > 0) {
                            _speakPosition(page);
                            startTimer();
                          } else {
                            _stopMusic();
                          }
                        });
                      },
                      children: [
                        _buildExercisePage(widget.imagePath1),
                        _buildExercisePage(widget.imagePath2),
                        _buildExercisePage(widget.imagePath3),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                        padding: const EdgeInsets.all(34),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 252, 251, 251).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 100,
                              color: Colors.amber,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Поздравляем!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Вы успешно завершили упражнение!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () {
                                _stopMusic();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                minimumSize: const Size(200, 50),
                              ),
                              child: const Text(
                                'Закрыть',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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

  Widget _buildExercisePage(String imagePath) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: const Color.fromARGB(206, 163, 214, 165),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SvgPicture.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 163, 214, 165),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                if (currentPage == 0 && !isTimerRunning)
                  ElevatedButton(
                    onPressed: _showFiveSecondAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 155, 193, 102),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Начать упражнение',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (isTimerRunning)
                  Text(
                    '${timerDuration.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: currentPage > 0
                            ? const Color(0xFF92A880)
                            : Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: currentPage > 0
                            ? () {
                          if (!mounted) return;
                          setState(() {
                            timer?.cancel();
                            isTimerRunning = false;
                            pageController.jumpToPage(currentPage - 1);
                          });
                        }
                            : null,
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 50),
                    Text(
                      'Позиция ${currentPage + 1} из 3',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 50),
                    Container(
                      decoration: BoxDecoration(
                        color: currentPage < 2
                            ? const Color(0xFF92A880)
                            : Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: currentPage < 2
                            ? () {
                          if (!mounted) return;
                          setState(() {
                            timer?.cancel();
                            isTimerRunning = false;
                            pageController.jumpToPage(currentPage + 1);
                          });
                        }
                            : null,
                        icon: const Icon(Icons.arrow_forward),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}