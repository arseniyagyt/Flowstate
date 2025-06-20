import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowstate/services/colors.dart';
import 'package:flowstate/services/snackbar.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flowstate/pages/login_page.dart';
import 'package:firebase_database/firebase_database.dart'; // <-- ИЗМЕНЕНИЕ: Добавлен импорт

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nicknameController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  User? get user => _auth.currentUser;
  bool isLoading = false;
  int? _selectedAvatarId;
  bool _isAvatarSelectionOpen = false;
  bool _isNotificationsEnabled = true;
  double _voiceVolume = 50.0;
  double _musicVolume = 50.0;
  String? _selectedVoice;
  String? _selectedMusicTrack;
  List<dynamic> _availableVoices = [];

  final List<Map<String, dynamic>> _availableAvatars = [
    {'id': 1, 'image': 'assets/male.png', 'name': 'Мужчина'},
    {'id': 2, 'image': 'assets/female.png', 'name': 'Женщина'},
  ];

  final List<Map<String, String>> _availableMusicTracks = [
    {'id': 'ambient1', 'name': 'Спокойный эмбиент', 'path': 'assets/music/ambient1.mp3'},
    {'id': 'ambient2', 'name': 'Мягкий эмбиент', 'path': 'assets/music/ambient2.mp3'},
    {'id': 'nature', 'name': 'Звуки природы', 'path': 'assets/music/meditation.mp3'},
    {'id': 'meditation', 'name': 'Медитация', 'path': 'assets/music/nature.mp3'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSettings();
    _initializeTts();
    _nicknameController.text = user?.email?.split('@')[0] ?? '';
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("ru-RU");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(_voiceVolume / 100);
    try {
      var voices = await _flutterTts.getVoices;
      setState(() {
        _availableVoices = voices.where((voice) => voice['locale'] == 'ru-RU').toList();
        if (_selectedVoice == null && _availableVoices.isNotEmpty) {
          _selectedVoice = _availableVoices[0]['name'];
          _flutterTts.setVoice({"name": "$_selectedVoice", "locale": "ru-RU"});
        }
      });
    } catch (e) {
      debugPrint('Ошибка загрузки голосов: $e');
    }
  }

  Future<void> _testVoice() async {
    await _flutterTts.stop();
    await _flutterTts.speak("Проверка");
  }

  Future<void> _testMusic() async {
    try {
      if (_selectedMusicTrack != null) {
        await _audioPlayer.stop();
        final track = _availableMusicTracks.firstWhere((t) => t['id'] == _selectedMusicTrack);
        await _audioPlayer.setVolume(_musicVolume / 100);
        await _audioPlayer.play(AssetSource(track['path']!.replaceFirst('assets/', '')));
        Timer(const Duration(seconds: 5), () async {
          await _audioPlayer.stop();
        });
      }
    } catch (e) {
      debugPrint('Ошибка воспроизведения музыки: $e');
      SnackBarService.showSnackBar(context, 'Ошибка воспроизведения музыки', true);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    setState(() => isLoading = true);
    try {
      final doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          _nicknameController.text = doc.data()?['nickname'] ?? user!.email!.split('@')[0];
          _selectedAvatarId = doc.data()?['avatarId'];
        });
      }
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка загрузки профиля: $e', true);
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceVolume = prefs.getDouble('voiceVolume') ?? 50.0;
      _musicVolume = prefs.getDouble('musicVolume') ?? 50.0;
      _isNotificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _selectedVoice = prefs.getString('selectedVoice');
      _selectedMusicTrack = prefs.getString('selectedMusicTrack') ?? _availableMusicTracks[0]['id'];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('voiceVolume', _voiceVolume);
    await prefs.setDouble('musicVolume', _musicVolume);
    await prefs.setBool('notificationsEnabled', _isNotificationsEnabled);
    if (_selectedVoice != null) {
      await prefs.setString('selectedVoice', _selectedVoice!);
    }
    if (_selectedMusicTrack != null) {
      await prefs.setString('selectedMusicTrack', _selectedMusicTrack!);
    }
    await _flutterTts.setVolume(_voiceVolume / 100);
  }

  Future<bool> _isNicknameUnique(String nickname) async {
    if (nickname.isEmpty) return false;
    try {
      final query = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return true;
      if (query.docs.first.id == user?.uid) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveProfile() async {
    if (_nicknameController.text.isEmpty || user == null) {
      SnackBarService.showSnackBar(context, 'Введите никнейм', true);
      return;
    }

    final isUnique = await _isNicknameUnique(_nicknameController.text);
    if (!isUnique) {
      SnackBarService.showSnackBar(context, 'Этот никнейм уже занят', true);
      return;
    }

    setState(() => isLoading = true);
    try {
      await _firestore.collection('users').doc(user!.uid).set({
        'nickname': _nicknameController.text,
        'avatarId': _selectedAvatarId,
        'email': user!.email,
      }, SetOptions(merge: true));

      if (!mounted) return;
      SnackBarService.showSnackBar(context, 'Профиль сохранён', false);
    } catch (e) {
      if (!mounted) return;
      SnackBarService.showSnackBar(context, 'Ошибка сохранения: $e', true);
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  // <-- ИЗМЕНЕНИЕ: Полностью заменен метод _signOut
  Future<void> _signOut() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      // 1. Устанавливаем статус "не в сети" в Realtime Database
      await FirebaseDatabase.instance.ref('presence/${currentUser.uid}').update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });

      // 2. Выходим из аккаунта Firebase Auth
      await _auth.signOut();

      // 3. Перенаправляем на экран входа
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarService.showSnackBar(context, 'Ошибка выхода: $e', true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

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
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(226, 255, 255, 255),
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(28, 0, 0, 0),
                          spreadRadius: 3,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          "Профиль",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isAvatarSelectionOpen = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: avatarBorderColor,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _selectedAvatarId != null
                                      ? AssetImage(
                                    _availableAvatars.firstWhere(
                                          (a) => a['id'] == _selectedAvatarId,
                                      orElse: () => _availableAvatars[0],
                                    )['image'],
                                  )
                                      : null,
                                  child: _selectedAvatarId == null
                                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                                      : null,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                decoration: BoxDecoration(
                                  color: highlightBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _nicknameController,
                                      decoration: InputDecoration(
                                        labelText: "Ник",
                                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: secondaryColor),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      'Email: ${user?.email ?? "Не указан"}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  "Сохранить",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            SizedBox(
                              width: 120,
                              child: OutlinedButton(
                                onPressed: isLoading ? null : _signOut,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  "Выйти",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        const Text(
                          "Настройки",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color: highlightBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Голос",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "${_voiceVolume.round()}%",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _voiceVolume,
                                min: 0,
                                max: 100,
                                divisions: 100,
                                activeColor: secondaryColor,
                                inactiveColor: Colors.grey,
                                onChanged: (value) {
                                  setState(() => _voiceVolume = value);
                                },
                                onChangeEnd: (value) async {
                                  await _saveSettings();
                                  await _testVoice();
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Выбор голоса",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: _selectedVoice,
                                    hint: const Text("Выберите голос"),
                                    items: _availableVoices.map((voice) {
                                      return DropdownMenuItem<String>(
                                        value: voice['name'],
                                        child: Text(
                                          voice['name'],
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) async {
                                      if (value != null) {
                                        setState(() => _selectedVoice = value);
                                        await _flutterTts.setVoice({"name": value, "locale": "ru-RU"});
                                        await _saveSettings();
                                        await _testVoice();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Громкость музыки",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "${_musicVolume.round()}%",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _musicVolume,
                                min: 0,
                                max: 100,
                                divisions: 100,
                                activeColor: secondaryColor,
                                inactiveColor: Colors.grey,
                                onChanged: (value) {
                                  setState(() => _musicVolume = value);
                                },
                                onChangeEnd: (value) async {
                                  await _saveSettings();
                                  await _testMusic();
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Выбор музыки",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: _selectedMusicTrack,
                                    hint: const Text("Выберите трек"),
                                    items: _availableMusicTracks.map((track) {
                                      return DropdownMenuItem<String>(
                                        value: track['id'],
                                        child: Text(
                                          track['name']!,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) async {
                                      if (value != null) {
                                        setState(() => _selectedMusicTrack = value);
                                        await _saveSettings();
                                        await _testMusic();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color: highlightBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Уведомления",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              Switch(
                                value: _isNotificationsEnabled,
                                onChanged: (value) {
                                  setState(() => _isNotificationsEnabled = value);
                                  _saveSettings();
                                },
                                activeColor: secondaryColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isAvatarSelectionOpen)
            Center(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Выберите аватар', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: _availableAvatars.map((avatar) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatarId = avatar['id'];
                              _isAvatarSelectionOpen = false;
                            });
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: AssetImage(avatar['image']),
                                child: avatar['id'] == _selectedAvatarId
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                avatar['name'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isAvatarSelectionOpen = false),
                        child: const Text('Закрыть'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}