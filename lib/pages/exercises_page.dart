import 'package:flowstate/services/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                          "Упражнения",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildExerciseCard(
                        context,
                        'Анантасана',
                        'assets/Anantasana_1.svg',
                        'assets/Anantasana_2.svg',
                        'assets/Anantasana_3.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Бхуджангасана',
                        'assets/Bhujangasana_1.svg',
                        'assets/Bhujangasana_2.svg',
                        'assets/Bhujangasana_3.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Маха Мудра',
                        'assets/MahaMudra_1.svg',
                        'assets/MahaMudra_2.svg',
                        'assets/MahaMudra_3.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Паригхасана',
                        'assets/Parigkhasana_1.svg',
                        'assets/Parigkhasana_2.svg',
                        'assets/Parigkhasana_3.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Триконасана',
                        'assets/Trikonasana_1.svg',
                        'assets/Trikonasana_2.svg',
                        'assets/Trikonasana_3.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Пашчимоттанасана',
                        'assets/idk_1.svg',
                        'assets/idk_2.svg',
                        'assets/idk_3.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Баласана',
                        'assets/Balasana_1.svg',
                        'assets/Balasana_2.svg',
                        'assets/Balasana_3.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Падмасана',
                        'assets/Padmasana_1.svg',
                        'assets/Padmasana_2.svg',
                        'assets/Padmasana_3.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Супта Вирасана',
                        'assets/SuptaVirasana_1.svg',
                        'assets/SuptaVirasana_2.svg',
                        'assets/SuptaVirasana_3.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Шавасана',
                        'assets/Shavasana_1.svg',
                        'assets/Shavasana_1.svg',
                        'assets/Shavasana_1.svg',
                      ),
                      _buildExerciseCard(
                        context,
                        'Супта Свастикасана',
                        'assets/SuptaSvastikasana_1.svg',
                        'assets/SuptaSvastikasana_2.svg',
                        'assets/SuptaSvastikasana_2.svg',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    String name,
    String image1,
    String image2,
    String image3,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(
              exerciseName: name,
              imagePath1: image1,
              imagePath2: image2,
              imagePath3: image3,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF92A880),
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SvgPicture.asset(
                  image1,
                  width: 120,
                  height: 120,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  // Словарь с текстами озвучки для каждого упражнения, с SSML для пауз
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

  // Словарь с длительностями таймеров для каждой позиции (в секундах)
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

  // Список доступных музыкальных треков (синхронизирован с AccountScreen)
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

  // Загрузка настроек голоса и музыки из SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceVolume = prefs.getDouble('voiceVolume') ?? 50.0;
      _selectedVoice = prefs.getString('selectedVoice');
      _musicVolume = prefs.getDouble('musicVolume') ?? 50.0;
      _selectedMusicTrack = prefs.getString('selectedMusicTrack') ?? _availableMusicTracks[0]['id'];
    });
  }

  // Инициализация настроек TTS
  Future<void> _initTts() async {
    await flutterTts.setLanguage("ru-RU");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(_voiceVolume / 100);
    await flutterTts.setPitch(1.0);
    if (_selectedVoice != null) {
      await flutterTts.setVoice({"name": "$_selectedVoice", "locale": "ru-RU"});
    }
  }

  // Метод для озвучивания позиции с SSML
  Future<void> _speakPosition(int page) async {
    final instructions = exerciseInstructions[widget.exerciseName] ?? ['<speak>Позиция ${page + 1}</speak>'];
    String text = instructions[page];

    await flutterTts.stop();

    try {
      await flutterTts.speak(text);
    } catch (e) {
      // Fallback: убираем SSML-теги и пробуем снова
      final fallbackText = text
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll(RegExp(r'<break time="[^"]*"/>'), ', ');
      await flutterTts.speak(fallbackText);
    }
  }

  // Воспроизведение музыки
  Future<void> _playMusic() async {
    if (_selectedMusicTrack != null) {
      try {
        final track = _availableMusicTracks.firstWhere((t) => t['id'] == _selectedMusicTrack);
        await audioPlayer.setVolume(_musicVolume / 100);
        await audioPlayer.play(AssetSource(track['path']!.replaceFirst('assets/', '')), mode: PlayerMode.mediaPlayer);
        await audioPlayer.setReleaseMode(ReleaseMode.loop); // Зацикливаем трек
      } catch (e) {
        debugPrint('Ошибка воспроизведения музыки: $e');
      }
    }
  }

  // Остановка музыки
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
    setState(() {
      isTimerRunning = true;
      timerDuration = exerciseTimers[widget.exerciseName]![currentPage];
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
              _stopMusic(); // Останавливаем музыку при завершении упражнения
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
        await _playMusic(); // Начинаем музыку
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
                          _stopMusic(); // Останавливаем музыку при выходе
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
                        setState(() {
                          currentPage = page;
                          isTimerRunning = false;
                          timer?.cancel();
                          if (page > 0) {
                            _speakPosition(page);
                            startTimer();
                          } else {
                            _stopMusic(); // Останавливаем музыку при возврате на первую позицию
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
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 150),
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
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () {
                              _stopMusic(); // Останавливаем музыку при закрытии
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
                    '$timerDuration',
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