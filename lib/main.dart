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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowstate/pages/joint_workouts_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null && !auth.currentUser!.emailVerified) {
    await auth.signOut();
  } else if (auth.currentUser != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser!.uid)
        .update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow State',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.lilitaOneTextTheme(
          Theme.of(context).textTheme.copyWith(
            displayLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            displayMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            displaySmall: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            headlineMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            headlineSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            titleLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            bodyLarge: const TextStyle(fontSize: 16),
            bodyMedium: const TextStyle(fontSize: 14),
            labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            labelMedium: const TextStyle(fontSize: 12),
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
        '/joint': (context) => const JointWorkoutScreen()
      },
      initialRoute: '/',
    );
  }
}