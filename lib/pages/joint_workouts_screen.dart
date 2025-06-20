import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowstate/services/snackbar.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowstate/services/colors.dart';
import 'package:intl/intl.dart';

class JointWorkoutScreen extends StatefulWidget {
  final String sessionId;
  final bool isHost;

  const JointWorkoutScreen({
    super.key,
    required this.sessionId,
    this.isHost = false,
  });

  @override
  State<JointWorkoutScreen> createState() => _JointWorkoutScreenState();
}

class _JointWorkoutScreenState extends State<JointWorkoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // Состояния UI и тренировки
  String _workoutName = "Загрузка...";
  List<Map<String, dynamic>> _exercisesData = [];
  bool _isLoading = true;
  bool _workoutStarted = false;
  bool _showPraise = false;
  bool _completionWasProcessed = false;

  // Синхронизируемые состояния
  int _currentExerciseIndex = 0;
  int _currentPage = 0;
  bool _isTimerRunning = false;
  int _secondsRemaining = 30;
  bool _isPaused = true;

  // Подписки
  StreamSubscription? _workoutStateSubscription;
  StreamSubscription? _messagesSubscription;
  List<Map<String, dynamic>> _messages = [];

  // Данные участников
  String? _hostId, _participantId, _hostName, _participantName;
  int? _hostAvatarId, _participantAvatarId;
  bool _isChatVisible = false;

  // TTS и Audio
  late FlutterTts _flutterTts;
  late AudioPlayer _audioPlayer;
  double _voiceVolume = 50.0, _musicVolume = 50.0;
  String? _selectedVoice, _selectedMusicTrack;
  Timer? _timer;
  bool _isMusicPlaying = false;

  // Данные для TTS и таймеров
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
    'Супта Вирасана': [30, 60, 120],
    'Шавасана': [30, 30, 60],
    'Супта Свастикасана': [30, 30, 60],
  };
  final List<Map<String, String>> _availableMusicTracks = [
    {'id': 'ambient1', 'name': 'Спокойный эмбиент', 'path': 'assets/music/ambient1.mp3'},
    {'id': 'ambient2', 'name': 'Мягкий эмбиент', 'path': 'assets/music/ambient2.mp3'},
    {'id': 'nature', 'name': 'Звуки природы', 'path': 'assets/music/nature.mp3'},
    {'id': 'meditation', 'name': 'Медитация', 'path': 'assets/music/meditation.mp3'},
  ];

  // Маппинг для аватаров
  final Map<int, String> _avatarMap = {
    1: 'male.png',
    2: 'female.png',
  };

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();
    _loadSettingsAndInit();
    if (_auth.currentUser != null) {
      _listenToWorkoutState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _chatScrollController.dispose();
    _workoutStateSubscription?.cancel();
    _messagesSubscription?.cancel();
    _flutterTts.stop();
    _stopMusic();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    _voiceVolume = prefs.getDouble('voiceVolume') ?? 50.0;
    _selectedVoice = prefs.getString('selectedVoice');
    _musicVolume = prefs.getDouble('musicVolume') ?? 50.0;
    _selectedMusicTrack = prefs.getString('selectedMusicTrack') ?? 'ambient1';
    await _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(_voiceVolume / 100);
    await _flutterTts.setPitch(1.0);
    if (_selectedVoice != null) {
      await _flutterTts.setVoice({"name": "$_selectedVoice", "locale": "ru-RU"});
    }
  }

  void _listenToWorkoutState() {
    _workoutStateSubscription = _firestore
        .collection('joint_sessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data()!;

      if (_isLoading) {
        _workoutName = data['workoutName'];
        _exercisesData = List<Map<String, dynamic>>.from(data['exercises']);
        _hostId = data['hostId'];
        if (data['participantId'] != null) {
          _participantId = data['participantId'];
          await _loadUserNames();
        }
        _isLoading = false;
      }

      if (_participantId == null && data['participantId'] != null) {
        _participantId = data['participantId'];
        await _loadUserNames();
      }

      final status = data['status'] as String?;
      final newIsTimerRunning = data['isTimerRunning'] ?? false;
      final newIsPaused = data['isPaused'] ?? true;
      final newExerciseIndex = data['currentExerciseIndex'] ?? 0;
      final newPage = data['currentPage'] ?? 0;

      if (!widget.isHost && (_isTimerRunning != newIsTimerRunning || _isPaused != newIsPaused)) {
        setState(() {
          _isTimerRunning = newIsTimerRunning;
          _isPaused = newIsPaused;
        });
        if (newIsTimerRunning && !newIsPaused) {
          _startLocalTimer();
          await _playMusic();
          await _speak(_currentExerciseIndex, _currentPage); // Speak for first position
        } else {
          _timer?.cancel();
        }
      }

      if (newExerciseIndex != _currentExerciseIndex || newPage != _currentPage) {
        if (!widget.isHost) await _speak(newExerciseIndex, newPage);
        setState(() {
          _currentExerciseIndex = newExerciseIndex;
          _currentPage = newPage;
          _secondsRemaining = data['secondsRemaining'] ?? 30;
        });
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining = data['secondsRemaining'] ?? 30;
          });
        }
      }

      if (status == 'completed' && !_completionWasProcessed) {
        _completionWasProcessed = true;
        await _recordWorkoutCompletion();
      }

      if (mounted) {
        setState(() {
          if (!_workoutStarted && status == 'active') {
            _workoutStarted = true;
            _listenToMessages();
          }
          _showPraise = status == 'completed';
          if (_showPraise) {
            _stopMusic();
            _timer?.cancel();
          }
        });
      }

      if (status == 'rejected' || status == 'cancelled') {
        if (mounted) {
          SnackBarService.showSnackBar(context, 'Приглашение отклонено или отменено.', false);
          Navigator.of(context).pop();
        }
      }
    });
  }

  Future<void> _loadUserNames() async {
    if (_hostId != null) {
      final doc = await _firestore.collection('users').doc(_hostId).get();
      if (mounted) {
        setState(() {
          _hostName = doc.data()?['nickname'] ?? 'Хост';
          _hostAvatarId = doc.data()?['avatarId'];
          debugPrint('Хост: $_hostName, AvatarId: $_hostAvatarId');
        });
      }
    }
    if (_participantId != null) {
      final doc = await _firestore.collection('users').doc(_participantId).get();
      if (mounted) {
        setState(() {
          _participantName = doc.data()?['nickname'] ?? 'Участник';
          _participantAvatarId = doc.data()?['avatarId'];
          debugPrint('Участник: $_participantName, AvatarId: $_participantAvatarId');
        });
      }
    }
  }

  Future<void> _updateFirestoreState(Map<String, dynamic> data) async {
    if (!widget.isHost) return;
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await _firestore.collection('joint_sessions').doc(widget.sessionId).update(data);
  }

  Future<void> _recordWorkoutCompletion() async {
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
          debugPrint("Тренировка на сегодня уже засчитана для ${user.uid}.");
          return;
        }

        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          debugPrint("Документ пользователя ${user.uid} не найден.");
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

      debugPrint("Данные о тренировке успешно обновлены для ${user.uid}!");

    } catch (e) {
      debugPrint('Ошибка атомарного обновления данных тренировки для ${user.uid}: $e');
      if (mounted) {
        SnackBarService.showSnackBar(context, 'Ошибка обновления данных тренировки', true);
      }
    }
  }

  void _startWorkout() {
    if (!widget.isHost || _exercisesData.isEmpty) return;
    _isPaused = true;
    _secondsRemaining = exerciseTimers[_exercisesData[0]['name']]![0];
    _updateFirestoreState({
      'status': 'active',
      'isPaused': _isPaused,
      'secondsRemaining': _secondsRemaining,
      'currentExerciseIndex': 0,
      'currentPage': 0,
    }).then((_) => _showFiveSecondAlertAndStart());
  }

  void _showFiveSecondAlertAndStart() {
    SnackBarService.showSnackBar(context, 'Приготовьтесь! 5 секунд...', false);
    Timer(const Duration(seconds: 5), () async {
      if (mounted) {
        _isPaused = false;
        await _updateFirestoreState({'isPaused': false, 'isTimerRunning': true});
        await _playMusic();
        await _speak(_currentExerciseIndex, _currentPage);
        _startLocalTimer();
      }
    });
  }

  void _startNextPosition() async {
    if (mounted) {
      _isPaused = false;
      await _updateFirestoreState({'isPaused': false, 'isTimerRunning': true});
      await _speak(_currentExerciseIndex, _currentPage);
      _startLocalTimer();
    }
  }

  void _startLocalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        if (widget.isHost && _secondsRemaining % 2 == 0) {
          _updateFirestoreState({'secondsRemaining': _secondsRemaining});
        }
        if (mounted) setState(() {});
      } else {
        timer.cancel();
        _isTimerRunning = false;
        if (widget.isHost) _moveToNextStep();
      }
    });
  }

  void _moveToNextStep() {
    if (!widget.isHost) return;

    if (_currentPage < 2) {
      _currentPage++;
    } else if (_currentExerciseIndex < _exercisesData.length - 1) {
      _currentExerciseIndex++;
      _currentPage = 0;
    } else {
      _endWorkout();
      return;
    }

    _isPaused = true;
    _secondsRemaining = exerciseTimers[_exercisesData[_currentExerciseIndex]['name']]![_currentPage];

    _updateFirestoreState({
      'currentExerciseIndex': _currentExerciseIndex,
      'currentPage': _currentPage,
      'isTimerRunning': false,
      'isPaused': true,
      'secondsRemaining': _secondsRemaining,
    }).then((_) => _startNextPosition());
  }

  void _moveToPreviousStep() {
    if (!widget.isHost) return;

    if (_currentPage > 0) {
      _currentPage--;
    } else if (_currentExerciseIndex > 0) {
      _currentExerciseIndex--;
      _currentPage = 2;
    } else {
      return;
    }

    _isPaused = true;
    _secondsRemaining = exerciseTimers[_exercisesData[_currentExerciseIndex]['name']]![_currentPage];

    _updateFirestoreState({
      'currentExerciseIndex': _currentExerciseIndex,
      'currentPage': _currentPage,
      'isTimerRunning': false,
      'isPaused': true,
      'secondsRemaining': _secondsRemaining,
    }).then((_) => _startNextPosition());
  }

  Future<void> _endWorkout() async {
    if (!widget.isHost) return;
    _timer?.cancel();
    _stopMusic();

    await _updateFirestoreState({
      'status': 'completed',
      'isTimerRunning': false,
      'isPaused': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _speak(int exerciseIdx, int page) async {
    if (exerciseIdx >= _exercisesData.length) return;
    final exerciseName = _exercisesData[exerciseIdx]['name']!;
    final instructions = exerciseInstructions[exerciseName] ?? ['<speak>Позиция ${page + 1}</speak>'];
    if (page >= instructions.length) return;
    String text = instructions[page];

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
      debugPrint('TTS played for ${widget.isHost ? 'host' : 'participant'}: $text');
    } catch (e) {
      final fallbackText = text.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll(RegExp(r'<break time="[^"]*"/>'), ', ');
      await _flutterTts.speak(fallbackText);
      debugPrint('TTS fallback played for ${widget.isHost ? 'host' : 'participant'}: $fallbackText, error: $e');
    }
  }

  Future<void> _playMusic() async {
    if (_isMusicPlaying || _selectedMusicTrack == null) return;

    try {
      final track = _availableMusicTracks.firstWhere((t) => t['id'] == _selectedMusicTrack);
      await _audioPlayer.setVolume(_musicVolume / 100);
      await _audioPlayer.play(AssetSource(track['path']!.replaceFirst('assets/', '')), mode: PlayerMode.mediaPlayer);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _isMusicPlaying = true;
      debugPrint('Music started for user ${widget.isHost ? 'host' : 'participant'}');
    } catch (e) {
      debugPrint('Ошибка воспроизведения музыки: $e');
      if (mounted) {
        SnackBarService.showSnackBar(context, 'Ошибка при воспроизведении музыки', false);
      }
    }
  }

  Future<void> _stopMusic() async {
    try {
      await _audioPlayer.stop();
      _isMusicPlaying = false;
      debugPrint('Music stopped for user ${widget.isHost ? 'host' : 'participant'}');
    } catch (e) {
      debugPrint('Ошибка остановки музыки: $e');
    }
  }

  void _listenToMessages() {
    _messagesSubscription = _firestore
        .collection('joint_sessions')
        .doc(widget.sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _messages = snapshot.docs.map((doc) => {
              'id': doc.id,
              'senderId': doc['senderId'],
              'senderName': doc['senderName'],
              'message': doc['message'],
              'timestamp': (doc['timestamp'] as Timestamp).toDate(),
            }).toList();
      });
      // Auto-scroll to latest message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    final senderName = (user.uid == _hostId ? _hostName : _participantName) ?? 'Пользователь';

    try {
      await _firestore
          .collection('joint_sessions')
          .doc(widget.sessionId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': senderName,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
      debugPrint('Message sent by ${user.uid}: $message');
    } catch (e) {
      debugPrint('Ошибка отправки сообщения: $e');
      if (mounted) {
        SnackBarService.showSnackBar(context, 'Ошибка при отправке сообщения', false);
      }
    }
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
                _buildTopBar(),
                Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _showPraise
                            ? _buildPraiseWidget()
                            : !_workoutStarted
                                ? _buildWaitingWidget()
                                : _buildWorkoutContent()),
                if (_workoutStarted && !_showPraise && _isChatVisible) _buildChatSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
          child: Text(
            _exercisesData.isNotEmpty ? '$_workoutName (${_currentExerciseIndex + 1}/${_exercisesData.length})' : _workoutName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Positioned(
            left: 0,
            child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 30),
                onPressed: () => Navigator.of(context).pop())),
        if (_workoutStarted && !_showPraise)
          Positioned(
              right: 0,
              child: IconButton(
                  icon: Icon(_isChatVisible ? Icons.chat_bubble : Icons.chat_bubble_outline, size: 30),
                  onPressed: () => setState(() => _isChatVisible = !_isChatVisible))),
      ],
    );
  }

  Widget _buildWorkoutContent() {
    if (_exercisesData.isEmpty) return const Center(child: Text("Ошибка: нет упражнений."));
    final currentExercise = _exercisesData[_currentExerciseIndex];
    final images = [currentExercise['image1'], currentExercise['image2'], currentExercise['image3']];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAvatarWidget(_hostAvatarId, _hostName),
                  _participantId != null
                      ? _buildAvatarWidget(_participantAvatarId, _participantName)
                      : _buildWaitingAvatar(),
                ]),
          ),
          Expanded(
              child: Container(
            width: double.infinity,
            decoration:
                BoxDecoration(color: const Color.fromARGB(206, 163, 214, 165), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SvgPicture.asset(images[_currentPage]!, fit: BoxFit.contain)),
            ),
          )),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration:
                BoxDecoration(color: const Color.fromARGB(255, 163, 214, 165), borderRadius: BorderRadius.circular(15)),
            child: widget.isHost ? _buildHostControls() : _buildParticipantView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHostControls() {
    final bool isFirstEverStart = _currentExerciseIndex == 0 && _currentPage == 0 && _isPaused && !_isTimerRunning;

    if (isFirstEverStart) {
      return ElevatedButton(
        onPressed: _startWorkout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 155, 193, 102),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Начать тренировку', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      );
    }

    return Column(
      children: [
        Text(
          _secondsRemaining.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: _currentPage > 0 || _currentExerciseIndex > 0 ? () => _moveToPreviousStep() : null,
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF92A880)),
            ),
            ElevatedButton(
              onPressed: _endWorkout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Завершить', style: TextStyle(color: Colors.white)),
            ),
            IconButton(
              onPressed: () => _moveToNextStep(),
              icon: const Icon(Icons.arrow_forward),
              color: Colors.white,
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF92A880)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('Позиция ${_currentPage + 1} из 3', style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildParticipantView() {
    return Column(
      children: [
        Text(
          _secondsRemaining.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('Позиция ${_currentPage + 1} из 3', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        const Text("Тренировкой управляет хост", style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildPraiseWidget() {
    return Center(
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
            const Icon(Icons.star, size: 100, color: Colors.amber),
            const SizedBox(height: 20),
            const Text(
              'Поздравляем!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Вы успешно завершили совместную тренировку!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                minimumSize: const Size(200, 50),
              ),
              child: const Text('Закрыть', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingWidget() {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text("Ожидание второго участника...", textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (widget.isHost)
            ElevatedButton(onPressed: _startWorkout, child: const Text("Начать тренировку одному"))
        ],
      ),
    ));
  }

  Widget _buildAvatarWidget(int? avatarId, String? name) {
    final fallbackInitial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    final avatarFile = _avatarMap[avatarId];

    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[300],
          child: avatarFile != null
              ? ClipOval(
                  child: Image.asset(
                    'assets/avatars/$avatarFile',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Text(fallbackInitial, style: const TextStyle(fontSize: 20, color: Colors.black54)),
                  ),
                )
              : Text(fallbackInitial, style: const TextStyle(fontSize: 20, color: Colors.black54)),
        ),
        const SizedBox(height: 4),
        Text(name ?? '...', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildWaitingAvatar() {
    return const Column(
        children: [
          CircleAvatar(radius: 24, child: Icon(Icons.person_outline)),
          SizedBox(height: 4),
          Text('Ожидание...', style: TextStyle(fontSize: 12, color: Colors.grey))
        ]);
  }

  Widget _buildChatSection() {
    return Container(
      height: 250,
      color: Colors.white.withOpacity(0.8),
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Нет сообщений'))
                : ListView.builder(
                    controller: _chatScrollController,
                    reverse: true, // Latest messages at the bottom
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['senderId'] == _auth.currentUser?.uid;
                      final timestamp = message['timestamp'] as DateTime;
                      final formattedTime = DateFormat('HH:mm').format(timestamp);

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['senderName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message['message'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedTime,
                                style: const TextStyle(fontSize: 10, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}