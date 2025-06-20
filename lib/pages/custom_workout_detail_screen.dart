import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flowstate/services/colors.dart';
import 'package:flowstate/services/snackbar.dart';

class CustomWorkoutDetailScreen extends StatefulWidget {
  final String workoutName;
  final List<Map<String, dynamic>> exercises;

  const CustomWorkoutDetailScreen({
    super.key,
    required this.workoutName,
    required this.exercises,
  });

  @override
  State<CustomWorkoutDetailScreen> createState() =>
      _CustomWorkoutDetailScreenState();
}

class _CustomWorkoutDetailScreenState extends State<CustomWorkoutDetailScreen> {
  int _currentExerciseIndex = 0;
  bool _showPraise = false;
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _isTimerRunning = false;
  bool _isPaused = true;
  late FlutterTts _flutterTts;
  late AudioPlayer _audioPlayer;
  double _voiceVolume = 50.0;
  String? _selectedVoice;
  double _musicVolume = 50.0;
  String? _selectedMusicTrack;

  final Map<String, List<String>> exerciseInstructions = {
    'Анантасана': [
      '<speak>Позиция 1: Лягте на спину. Расслабьтесь, почувствуйте контакт тела с полом. На выдохе плавно перекатитесь на левый бок. Расположитесь так, чтобы вес тела равномерно распределился на левом боку. Теперь аккуратно приподнимите голову. Левую руку вытяните над головой, выстраивая одну линию с телом. Согните локоть и ладонью левой руки мягко поддержите голову — расположите её чуть выше уха. Дышите спокойно или сделайте 2–3 глубоких цикла дыхания.<break time="500ms"/></speak>',
      '<speak>Позиция 2: Согните правое колено. Правой рукой обхватите большой палец правой ноги: большой, указательный и средний пальцы плотно фиксируют стопу.<break time="500ms"/> На выдохе медленно выпрямите правую ногу и руку, поднимая их вертикально вверх. Представьте, как энергия от стопы тянется к кончикам пальцев.<break time="500ms"/></speak>',
      '<speak>Позиция 3: Удерживайте позу 15–20 секунд. Дышите ровно, сохраняя контроль над положением тела. На выдохе так же плавно согните колено и вернитесь в положение на боку. Не торопитесь — движение должно быть осознанным.<break time="500ms"/> Осторожно опустите голову с ладони и перекатитесь обратно на спину. Дайте себе момент отдыха.<break time="500ms"/> Теперь повторите всё в другую сторону: перекатитесь на правый бок, выполните те же шаги с левой ногой и рукой. Следите за симметрией — время удержания должно быть одинаковым для обеих сторон.<break time="500ms"/></speak>',
    ],
    'Бхуджангасана': [
      '<speak>Позиция 1: Лягте на живот<break time="500ms"/> ладони под плечами.</speak>',
      '<speak>Позиция 2: Поднимите грудь вверх<break time="500ms"/> вытягивая позвоночник.</speak>',
      '<speak>Позиция 3: Удерживайте позу<break time="500ms"/> дышите ровно.</speak>',
    ],
    'Маха Мудра': [
      '<speak>Позиция 1: Сядьте на пол, вытяните ноги перед собой. Почувствуйте, как копчик тянется к полу, а макушка — к потолку.<break time="500ms"/></speak>',
      '<speak>Позиция 2: Согните левое колено и аккуратно опустите его влево. Внешняя часть левого бедра и голени должна полностью касаться пола. Расположите левую пятку у внутренней поверхности левого бедра. Проверьте угол между ногами: вытянутая правая и согнутая левая должны создать чёткие 90 градусов.<break time="500ms"/> На вдохе вытяните руки вперед, к правой стопе.<break time="500ms"/></speak>',
      '<speak>Позиция 3: Обхватите большой палец правой ноги большим и указательным пальцами обеих рук. Медленно опустите подбородок к грудине. Следите за позвоночником: он должен оставаться вытянутым. Сделайте глубокий вдох. Напрягите мышцы живота, подтягивая их от нижней части к диафрагме.<break time="1000ms"/> Удерживайте позу от 1 до 3 минут, сохраняя ровный ритм дыхания.<break time="500ms"/></speak>',
    ],
    'Паригхасана': [
      '<speak>Позиция 1: Встаньте на колени, соединив лодыжки. Медленно вытяните правую ногу вправо. Стопу разверните в ту же сторону. Проверьте: плечи остаются над бёдрами, макушка тянется вверх. На вдохе раскройте руки в стороны.<break time="500ms"/></speak>',
      '<speak>Позиция 2: На выдохе плавно наклоните корпус и правую руку к вытянутой ноге. Опустите правое предплечье на голень, а ладонь разместите на лодыжке. Левую руку вытяните над головой.<break time="500ms"/></speak>',
      '<speak>Позиция 3: Левое ухо прижмите к верхней части левой руки. Удерживайте позу 30–60 секунд. Дышите ровно.<break time="500ms"/> На вдохе медленно верните корпус в вертикальное положение. Повторите асану влево.<break time="500ms"/></speak>',
    ],
    'Триконасана': [
      '<speak>Позиция 1: Стойте прямо. Сделайте вдох и расставьте стопы на ширину 90–105 см. Поднимите руки в стороны на уровень плеч.<break time="500ms"/></speak>',
      '<speak>Позиция 2: Разверните правую стопу на 90 градусов вправо. На выдохе наклоните корпус вправо. Опустите правую ладонь к правой лодыжке.<break time="500ms"/></speak>',
      '<speak>Позиция 3: Левую руку вытяните вверх. Взгляд направьте на большой палец поднятой руки. Удерживайте позу от 30 секунд до минуты.<break time="500ms"/></speak>',
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
      '<speak>Позиция 1: Сядьте в позу Героя: опустите ягодицы между пяток. На выдохе медленно отклоните корпус назад. Коснитесь пола локтями.<break time="2000ms"/></speak>',
      '<speak>Позиция 2: Перенесите вес с локтей, вытягивая руки вдоль тела. Опустите на пол верхнюю часть головы, затем затылок и спину.<break time="4000ms"/></speak>',
      '<speak>Позиция 3: Вытяните руки за голову. Дышите глубоко. Удерживайте положение столько, сколько комфортно.<break time="3000ms"/> Для выхода: Согните руки и вернитесь в сидячее положение.<break time="5000ms"/></speak>',
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();
    _loadSettings();
    _initTts();
    _secondsRemaining = _getCurrentTimerDuration();
  }

  int _getCurrentTimerDuration() {
    if (widget.exercises.isEmpty || _currentExerciseIndex >= widget.exercises.length) {
      return 30;
    }
    final exerciseName = widget.exercises[_currentExerciseIndex]['name'];
    return exerciseTimers[exerciseName]?[_currentPage] ?? 30;
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

      // Используем транзакцию для чтения и последующей записи
      await firestore.runTransaction((transaction) async {
        // 1. Проверяем, была ли уже тренировка сегодня
        final calendarDoc = await transaction.get(userCalendarRef);
        if (calendarDoc.exists && (calendarDoc.data()?['workouts']?[todayKey]?['completed'] == true)) {
          debugPrint("Тренировка на сегодня уже засчитана. Обновление не требуется.");
          return; // Выходим, если уже выполнено
        }

        // 2. Получаем текущий стрик и дату последней тренировки
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          debugPrint("Документ пользователя не найден.");
          return;
        }

        final data = userDoc.data() ?? {};
        final lastWorkoutStamp = data['lastWorkoutDate'] as Timestamp?;
        final streakDays = data['streakDays'] ?? 0;
        final lastWorkoutDate = lastWorkoutStamp?.toDate();

        // 3. Рассчитываем новый стрик
        int newStreak = 1;
        if (lastWorkoutDate != null) {
          final yesterday = today.subtract(const Duration(days: 1));
          if (DateTime(lastWorkoutDate.year, lastWorkoutDate.month, lastWorkoutDate.day)
              .isAtSameMomentAs(yesterday)) {
            newStreak = streakDays + 1;
          }
        }

        // 4. Готовим пакетную запись
        // Обновляем профиль пользователя
        transaction.update(userRef, {
          'lastWorkoutDate': Timestamp.fromDate(now),
          'streakDays': newStreak,
          'workoutHistory': FieldValue.arrayUnion([Timestamp.fromDate(now)]),
        });

        // Обновляем календарь пользователя
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
      _selectedMusicTrack =
          prefs.getString('selectedMusicTrack') ?? _availableMusicTracks[0]['id'];
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(_voiceVolume / 100);
    await _flutterTts.setPitch(1.0);
    if (_selectedVoice != null) {
      await _flutterTts.setVoice({"name": _selectedVoice!, "locale": "ru-RU"});
    }
  }

  Future<void> _speakPosition(int page) async {
    if (widget.exercises.isEmpty || _currentExerciseIndex >= widget.exercises.length) return;
    final exerciseName = widget.exercises[_currentExerciseIndex]['name'];
    final instructions =
        exerciseInstructions[exerciseName] ?? ['<speak>Позиция ${page + 1}</speak>'];
    String text = instructions[page];

    await _flutterTts.stop();

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      final fallbackText = text
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll(RegExp(r'<break time="[^"]*"/>'), ', ');
      await _flutterTts.speak(fallbackText);
    }
  }

  Future<void> _playMusic() async {
    if (_selectedMusicTrack != null) {
      try {
        final track = _availableMusicTracks
            .firstWhere((t) => t['id'] == _selectedMusicTrack);
        await _audioPlayer.setVolume(_musicVolume / 100);
        await _audioPlayer.play(AssetSource(track['path']!.replaceFirst('assets/', '')),
            mode: PlayerMode.mediaPlayer);
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      } catch (e) {
        debugPrint('Ошибка воспроизведения музыки: $e');
      }
    }
  }

  Future<void> _stopMusic() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Ошибка остановки музыки: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _flutterTts.stop();
    _stopMusic();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _pauseTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() {
        _isTimerRunning = false;
        _isPaused = true;
      });
    }
  }

  void _resumeTimer() {
    if (!_isTimerRunning && _isPaused) {
      setState(() {
        _isPaused = false;
      });
      _startTimer();
    }
  }

  void _showFiveSecondAlert() {
    SnackBarService.showSnackBar(
      context,
      'Подготовьтесь к следующему упражнению! 5 секунд...',
      false,
    );

    setState(() {
      _secondsRemaining = _getCurrentTimerDuration();
      _isPaused = true;
    });

    Timer(const Duration(seconds: 5), () async {
      if (mounted) {
        if (_currentExerciseIndex == 0 && _currentPage == 0) {
          await _playMusic();
        }
        _speakPosition(_currentPage);
        setState(() {
          _isPaused = false;
        });
        _startTimer();
      }
    });
  }

  void _nextExercise() {
    if (!mounted) return;
    setState(() {
      _timer?.cancel();
      _isTimerRunning = false;
      _isPaused = true;
      if (_currentExerciseIndex < widget.exercises.length - 1) {
        _currentExerciseIndex++;
        _currentPage = 0;
        _pageController.jumpToPage(0);
        _secondsRemaining = _getCurrentTimerDuration();
        _showFiveSecondAlert();
      } else {
        _showPraise = true;
        _updateWorkoutCompletion();
        _stopMusic();
      }
    });
  }

  void _startTimer() {
    if (!_isTimerRunning && !_isPaused) {
      setState(() {
        _isTimerRunning = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            timer.cancel();
            _isTimerRunning = false;

            if (_currentPage < 2) {
              _pageController.jumpToPage(_currentPage + 1);
            } else {
              _nextExercise();
            }
          }
        });
      });
    }
  }

  Widget _buildExercisePage(int positionIndex) {
    if (widget.exercises.isEmpty || _currentExerciseIndex >= widget.exercises.length) {
      return const Center(child: Text("Ошибка упражнения."));
    }
    final exercise = widget.exercises[_currentExerciseIndex];

    String? imagePath = 'assets/default_image.svg'; // Placeholder
    if (positionIndex == 0) {
      imagePath = exercise['image1'];
    } else if (positionIndex == 1) {
      imagePath = exercise['image2'];
    } else {
      imagePath = exercise['image3'];
    }

    if (imagePath == null) {
      return const Center(child: Text("Изображение не найдено."));
    }

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
                    placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
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
                if (_currentPage == 0 && !_isTimerRunning && _isPaused)
                  ElevatedButton(
                    onPressed: _showFiveSecondAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color.fromARGB(255, 155, 193, 102),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      _currentExerciseIndex == 0
                          ? 'Начать тренировку'
                          : 'Начать упражнение',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (_isTimerRunning)
                  Text(
                    '${_secondsRemaining.toString().padLeft(2, '0')}',
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
                        color: _currentPage > 0
                            ? const Color(0xFF92A880)
                            : Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _currentPage > 0
                            ? () {
                          if (!mounted) return;
                          setState(() {
                            _timer?.cancel();
                            _isTimerRunning = false;
                            _isPaused = true;
                            _pageController.jumpToPage(_currentPage - 1);
                            _secondsRemaining = _getCurrentTimerDuration();
                          });
                        }
                            : null,
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 50),
                    Text(
                      'Позиция ${_currentPage + 1} из 3',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 50),
                    Container(
                      decoration: BoxDecoration(
                        color: _currentPage < 2
                            ? const Color(0xFF92A880)
                            : Colors.grey.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _currentPage < 2
                            ? () {
                          if (!mounted) return;
                          setState(() {
                            _timer?.cancel();
                            _isTimerRunning = false;
                            _isPaused = false;
                            _pageController.jumpToPage(_currentPage + 1);
                            _secondsRemaining = _getCurrentTimerDuration();
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

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return const Scaffold(body: Center(child: Text("Нет упражнений для отображения.")));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset('assets/background.svg',
                fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 50),
                        child: Text(
                          '${widget.workoutName} (${_currentExerciseIndex + 1}/${widget.exercises.length})',
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
                      top: 0,
                      left: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 30,
                        ),
                        onPressed: () {
                          _stopMusic();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
                if (!_showPraise)
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (int page) {
                        if (!mounted) return;
                        setState(() {
                          _currentPage = page;
                          _timer?.cancel();
                          _isTimerRunning = false;
                          _isPaused = page == 0;
                          _secondsRemaining = _getCurrentTimerDuration();
                          if (page > 0) {
                            _isPaused = false;
                            _speakPosition(page);
                            _startTimer();
                          } else if (_currentExerciseIndex == 0) {
                            _stopMusic();
                          }
                        });
                      },
                      children: [
                        _buildExercisePage(0),
                        _buildExercisePage(1),
                        _buildExercisePage(2),
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
                          color: const Color.fromARGB(255, 252, 251, 251)
                              .withOpacity(0.9),
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
                              'Вы успешно завершили тренировку!',
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
}