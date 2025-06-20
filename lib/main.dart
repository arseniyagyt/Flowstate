import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flowstate/pages/login_page.dart';
import 'package:flowstate/pages/password_reset_page.dart';
import 'package:flowstate/pages/signup_page.dart';
import 'package:flowstate/pages/acc_page.dart';
import 'package:flowstate/services/firebase_stream.dart';
import 'package:flowstate/pages/home_page.dart';
import 'package:flowstate/pages/ready_workouts_page.dart';
import 'package:flowstate/pages/exercises_page.dart';
import 'package:flowstate/pages/create_workout_page.dart';
import 'package:flowstate/pages/joint_workouts_screen.dart';
import 'package:firebase_database/firebase_database.dart'; // Импорт для Realtime Database

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Инициализация Firebase
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance; // Инициализируем Realtime Database

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Пользователь вошел в систему
        _setupPresence(user.uid);
        debugPrint("main.dart: Пользователь ${user.uid} вошел в систему. Настройка присутствия.");
      } else {
        // Пользователь вышел из системы
        // Здесь можно очистить статус присутствия, если необходимо
        debugPrint("main.dart: Пользователь вышел из системы.");
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint("main.dart: currentUser is null in didChangeAppLifecycleState");
      return;
    }

    if (state == AppLifecycleState.resumed) {
      // Приложение вернулось из фонового режима
      _setOnlineStatus(currentUser.uid, true);
      debugPrint("main.dart: Приложение возобновлено. Устанавливаем онлайн для ${currentUser.uid}");
    } else if (state == AppLifecycleState.paused) {
      // Приложение перешло в фоновый режим
      // onDisconnect() должен позаботиться о статусе, когда соединение будет потеряно.
      // Не явно устанавливаем false здесь, чтобы избежать гонок с onDisconnect.
      debugPrint("main.dart: Приложение приостановлено. onDisconnect() позаботится о статусе.");
    } else if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      // Приложение полностью закрыто или неактивно (например, входящий звонок)
      // onDisconnect() все равно должен сработать, но здесь можно явно установить оффлайн
      _setOnlineStatus(currentUser.uid, false);
      debugPrint("main.dart: Приложение завершается/неактивно. Устанавливаем оффлайн для ${currentUser.uid}");
    }
  }

  // Установка статуса онлайн/оффлайн
  Future<void> _setOnlineStatus(String userId, bool isOnline) async {
    try {
      final userRef = _database.ref('presence/${userId}');
      await userRef.update({
        'isOnline': isOnline,
        'lastSeen': ServerValue.timestamp, // Обновляем время последнего посещения
      });
      debugPrint("main.dart: Пользователь $userId установлен как ${isOnline ? 'ONLINE' : 'OFFLINE'} в DB.");
    } catch (e) {
      debugPrint("main.dart: Ошибка установки ${isOnline ? 'ONLINE' : 'OFFLINE'} статуса для $userId: $e");
    }
  }

  void _setupPresence(String uid) {
    final userRef = _database.ref('presence/${uid}');
    final connectedRef = _database.ref('.info/connected');

    connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (connected) {
        debugPrint("main.dart: Realtime DB: Соединение установлено. Устанавливаем онлайн для $uid");
        userRef.set({
          'isOnline': true,
          'lastSeen': ServerValue.timestamp,
        }).then((_) {
          // Устанавливаем onDisconnect только после того, как убедились, что пользователь онлайн
          userRef.onDisconnect().update({
            'isOnline': false,
            'lastSeen': ServerValue.timestamp,
          }).then((_) {
            debugPrint("main.dart: Realtime DB: onDisconnect() установлен для $uid.");
          }).catchError((e) {
            debugPrint("main.dart: Ошибка установки onDisconnect() для $uid: $e");
          });
        }).catchError((e) {
          debugPrint("main.dart: Ошибка установки ONLINE статуса в DB для $uid: $e");
        });
      } else {
        debugPrint("main.dart: Realtime DB: Соединение потеряно для $uid. onDisconnect() сработает.");
      }
    }, onError: (error) {
      debugPrint("main.dart: Realtime DB: Ошибка слушателя .info/connected: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flowstate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        textTheme: GoogleFonts.lilitaOneTextTheme(
          const TextTheme(
            displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            displayMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 14),
            labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            labelMedium: TextStyle(fontSize: 12),
          ),
        ),
      ),
      routes: {
        '/': (context) => const FirebaseStream(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
        '/account': (context) => const AccountScreen(),
        '/exercises': (context) => const ExercisesScreen(),
        '/ready_workouts': (context) => const ReadyWorkoutsScreen(),
        '/create_workout': (context) => const CreateWorkoutScreen(),
      },
    );
  }
}