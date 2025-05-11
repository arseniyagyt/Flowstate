import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/colors.dart';
import 'package:flowstate/pages/acc_page.dart';
import 'package:flowstate/pages/login_page.dart';

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
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  static const List<Widget> _screens = [
    TrainingContent(),
    CalendarScreen(),
    StatsScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    final user = FirebaseAuth.instance.currentUser;

    if (index == 3 && user == null) {
      // Если пользователь не авторизован и пытается открыть профиль
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
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
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.home, 0),
                  activeIcon: _buildActiveNavIcon(Icons.home),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.calendar_today, 1),
                  activeIcon: _buildActiveNavIcon(Icons.calendar_today),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.bar_chart, 2),
                  activeIcon: _buildActiveNavIcon(Icons.bar_chart),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.person, 3),
                  activeIcon: _buildActiveNavIcon(Icons.person),
                  label: '',
                ),
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
      decoration: const BoxDecoration(
        color: Color.fromARGB(124, 236, 241, 229),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 24),
    );
  }

  Widget _buildActiveNavIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: accentColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 24),
    );
  }
}

class TrainingContent extends StatelessWidget {
  const TrainingContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Stack(
      children: [
        // SVG-фон
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/background.svg',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user == null) ...[
                const Text(
                  'Вы не авторизованы',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),
                _buildButton(
                  'ВОЙТИ',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ),
                ),
              ] else ...[
                Text(
                  'Добро пожаловать, ${user.email}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                _buildButton(
                  'УПРАЖНЕНИЯ',
                  () => Navigator.pushNamed(context, '/exercises'),
                ),
                const SizedBox(height: 40),
                _buildButton(
                  'ГОТОВЫЕ ТРЕНИРОВКИ',
                  () => Navigator.pushNamed(context, '/ready_workouts'),
                ),
                const SizedBox(height: 40),
                _buildButton(
                  'СОЗДАТЬ ТРЕНИРОВКУ',
                  () => Navigator.pushNamed(context, '/create_workout'),
                ),
              ],
            ],
          ),
        ),
      ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // SVG-фон
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/background.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Кнопка возврата назад
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          // Основное содержимое
          const Center(
            child: Text(
              "Экран упражнений (в разработке)",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class ReadyWorkoutsScreen extends StatelessWidget {
//   const ReadyWorkoutsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // SVG-фон
//           Positioned.fill(
//             child: SvgPicture.asset(
//               'assets/background.svg',
//               fit: BoxFit.cover,
//             ),
//           ),
//           // Кнопка возврата назад
//           Positioned(
//             top: 40,
//             left: 16,
//             child: IconButton(
//               icon: const Icon(
//                 Icons.arrow_back,
//                 color: Colors.black,
//                 size: 30,
//               ),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ),
//           // Основное содержимое
//           const Center(
//             child: Text(
//               "Экран готовых тренировок (в разработке)",
//               style: TextStyle(
//                 fontSize: 20,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class CreateWorkoutScreen extends StatelessWidget {
  const CreateWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // SVG-фон
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/background.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Кнопка возврата назад
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          // Основное содержимое
          const Center(
            child: Text(
              "Экран создания тренировки (в разработке)",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

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
          const Center(
            child: Text(
              "Экран календаря (в разработке)",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

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
          const Center(
            child: Text(
              "Экран статистики (в разработке)",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}