import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flowstate/services/snackbar.dart';
import 'package:flowstate/pages/joint_workouts_screen.dart';

class InvitationScreen extends StatelessWidget {
  final String sessionId;
  final String fromUserId;
  final String exerciseName;

  const InvitationScreen({
    super.key,
    required this.sessionId,
    required this.fromUserId,
    required this.exerciseName,
  });

  Future<Map<String, dynamic>> _getSenderInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(fromUserId)
        .get();
    return doc.data() ?? {};
  }

  Future<void> _respondToInvitation(BuildContext context, bool accept) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('joint_sessions')
          .doc(sessionId)
          .update({
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      if (accept) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'workout_invite_response',
          'response': 'accepted',
          'fromUserId': user.uid,
          'toUserId': fromUserId,
          'sessionId': sessionId,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      SnackBarService.showSnackBar(
          context, 'Ошибка обработки приглашения: $e', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getSenderInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final senderInfo = snapshot.data ?? {};
          final senderName = senderInfo['nickname'] ?? 'Пользователь';

          return Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/background.svg',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          size: 60,
                          color: Color(0xFF92A880),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Приглашение на тренировку',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '$senderName приглашает вас на совместную тренировку:',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          exerciseName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92A880),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _respondToInvitation(context, false);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                              child: const Text(
                                'Отклонить',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _respondToInvitation(context, true);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JointWorkoutScreen(
                                      sessionId: sessionId,
                                      isHost: false,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF92A880),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                              child: const Text(
                                'Принять',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}