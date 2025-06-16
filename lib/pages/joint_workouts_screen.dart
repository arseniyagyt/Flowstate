import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flowstate/services/snackbar.dart';
import '../services/colors.dart';
import 'exercises_page.dart'; 

class JointWorkoutScreen extends StatefulWidget {
  const JointWorkoutScreen({super.key});

  @override
  State<JointWorkoutScreen> createState() => _JointWorkoutScreenState();
}

class _JointWorkoutScreenState extends State<JointWorkoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  String? _selectedFriendId; // Selected friend's user ID
  String? _selectedExercise; // Selected exercise name
  String? _sessionId; // Unique ID for the joint workout session
  List<Map<String, dynamic>> _friends = []; // Friends list from Firestore
  Map<String, bool> _onlineStatus = {}; // Online status of users
  bool _isLoading = true;

  // List of exercises (same as in ExercisesScreen)
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Анантасана',
      'image1': 'assets/Anantasana_1.svg',
      'image2': 'assets/Anantasana_2.svg',
      'image3': 'assets/Anantasana_3.svg',
    },
    {
      'name': 'Бхуджангасана',
      'image1': 'assets/Bhujangasana_1.svg',
      'image2': 'assets/Bhujangasana_2.svg',
      'image3': 'assets/Bhujangasana_3.svg',
    },
    {
      'name': 'Маха Мудра',
      'image1': 'assets/MahaMudra_1.svg',
      'image2': 'assets/MahaMudra_2.svg',
      'image3': 'assets/MahaMudra_3.svg',
    },
    {
      'name': 'Паригхасана',
      'image1': 'assets/Parigkhasana_1.svg',
      'image2': 'assets/Parigkhasana_2.svg',
      'image3': 'assets/Parigkhasana_3.svg',
    },
    {
      'name': 'Триконасана',
      'image1': 'assets/Trikonasana_1.svg',
      'image2': 'assets/Trikonasana_2.svg',
      'image3': 'assets/Trikonasana_3.svg',
    },
    {
      'name': 'Пашчимоттанасана',
      'image1': 'assets/idk_1.svg',
      'image2': 'assets/idk_2.svg',
      'image3': 'assets/idk_3.svg',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackBarService.showSnackBar(
          context,
          'Войдите в аккаунт для совместных тренировок',
          true,
        );
        Navigator.of(context).pop();
      });
    } else {
      _loadFriends();
      _setupOnlineStatusListener();
      // Initialize session ID (will be updated when friend is selected)
      _sessionId = '${_auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // Load friends from Firestore (similar to StatsScreen)
  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final friendsSnapshot = await _firestore
          .collection('friends')
          .where('users', arrayContains: user.uid)
          .get();

      _friends = await Future.wait(
        friendsSnapshot.docs.map((doc) async {
          final friendId = doc.data()['users'].firstWhere((id) => id != user.uid);
          final userDoc = await _firestore.collection('users').doc(friendId).get();
          return {
            ...userDoc.data()!,
            'id': friendId,
            'docId': doc.id,
            'type': 'friend',
          };
        }),
      );
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка загрузки друзей: $e', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Listen to online status (similar to StatsScreen)
  void _setupOnlineStatusListener() {
    _firestore.collection('users').snapshots().listen((snapshot) {
      final statusMap = <String, bool>{};
      for (var doc in snapshot.docs) {
        statusMap[doc.id] = doc.data()['isOnline'] ?? false;
      }
      setState(() {
        _onlineStatus = statusMap;
      });
    });
  }

  // Send a chat message to Firestore
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedFriendId == null || _sessionId == null) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('joint_workouts')
          .doc(_sessionId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Пользователь',
        'text': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка отправки сообщения: $e', true);
    }
  }

  // Start the joint exercise
  void _startJointExercise() {
    if (_selectedFriendId == null) {
      SnackBarService.showSnackBar(context, 'Выберите друга', true);
      return;
    }
    if (_selectedExercise == null) {
      SnackBarService.showSnackBar(context, 'Выберите упражнение', true);
      return;
    }

    // Find the selected exercise details
    final exercise = _exercises.firstWhere((e) => e['name'] == _selectedExercise);

    // Navigate to ExerciseDetailScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(
          exerciseName: exercise['name'],
          imagePath1: exercise['image1'],
          imagePath2: exercise['image2'],
          imagePath3: exercise['image3'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/background.svg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                        child: const Text(
                          'Совместные тренировки',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                // Main content
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            // Friend selection
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Выберите друга',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: _selectedFriendId,
                              items: _friends
                                  .map<DropdownMenuItem<String>>((friend) => DropdownMenuItem<String>(
                                        value: friend['id'],
                                        child: Row(
                                          children: [
                                            Text(friend['nickname'] ?? 'Без ника'),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: _onlineStatus[friend['id']] ?? false
                                                    ? Colors.green
                                                    : Colors.grey,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedFriendId = value;
                                  // Update session ID with friend selection
                                  _sessionId =
                                      '${_auth.currentUser!.uid}_${value}_${DateTime.now().millisecondsSinceEpoch}';
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            // Exercise selection
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Выберите упражнение',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: _selectedExercise,
                              items: _exercises
                                  .map<DropdownMenuItem<String>>((exercise) => DropdownMenuItem<String>(
                                        value: exercise['name'],
                                        child: Text(exercise['name']),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedExercise = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            // Start exercise button
                            ElevatedButton(
                              onPressed: _startJointExercise,
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
                          ],
                        ),
                ),
                // Chat area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
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
                        Expanded(
                          child: _selectedFriendId == null || _sessionId == null
                              ? const Center(child: Text('Выберите друга для начала чата'))
                              : StreamBuilder<QuerySnapshot>(
                                  stream: _firestore
                                      .collection('joint_workouts')
                                      .doc(_sessionId)
                                      .collection('messages')
                                      .orderBy('timestamp', descending: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return const Center(child: Text('Ошибка загрузки чата'));
                                    }
                                    if (!snapshot.hasData) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    final messages = snapshot.data!.docs;

                                    return ListView.builder(
                                      reverse: true, // Newest messages at the bottom
                                      itemCount: messages.length,
                                      itemBuilder: (context, index) {
                                        final message = messages[index].data() as Map<String, dynamic>;
                                        final isMe = message['senderId'] == _auth.currentUser!.uid;

                                        return Align(
                                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isMe
                                                  ? const Color(0xFF92A880).withOpacity(0.8)
                                                  : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: isMe
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  message['senderName'],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  message['text'],
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                        // Chat input
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: 'Введите сообщение...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send, color: Color(0xFF92A880)),
                                onPressed: _sendMessage,
                              ),
                            ],
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
}