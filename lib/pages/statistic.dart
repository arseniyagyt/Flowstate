import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowstate/services/colors.dart';
import 'package:flowstate/services/snackbar.dart';
import 'package:firebase_database/firebase_database.dart'; // Импорт для Realtime Database
import 'package:intl/intl.dart'; // Для форматирования даты/времени
import 'package:flutter_svg/flutter_svg.dart'; // Импорт для SVG фона

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDatabase = FirebaseDatabase.instance; // Инициализация Realtime Database
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  int _selectedTab = 0;
  int _pendingRequestsCount = 0;
  Map<String, Map<String, dynamic>> _onlineStatus = {};
  List<String> _sentRequests = [];
  Map<String, int> _friendsStreaks = {};
  StreamSubscription? _presenceListener;

  final List<Map<String, dynamic>> _availableAvatars = [
    {'id': 1, 'image': 'assets/male.png', 'name': 'Мужчина'},
    {'id': 2, 'image': 'assets/female.png', 'name': 'Женщина'},
  ];

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      _loadData();
      _setupRequestListener();
      _setupPresenceListener();
      _loadSentRequests();
      _loadFriendsStreaks();
    }
  }

  @override
  void dispose() {
    _presenceListener?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendsStreaks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final friendsSnapshot = await _firestore
          .collection('friends')
          .where('users', arrayContains: user.uid)
          .get();

      final streaks = <String, int>{};

      for (var doc in friendsSnapshot.docs) {
        final friendId = doc.data()['users'].firstWhere((id) => id != user.uid);
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        streaks[friendId] = friendDoc.data()?['streakDays'] as int? ?? 0;
      }

      if (mounted) {
        setState(() {
          _friendsStreaks = streaks;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки streak друзей: $e');
    }
  }

  Future<void> _loadSentRequests() async {
    try {
      final snapshot = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: _auth.currentUser!.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          _sentRequests = snapshot.docs.map((doc) => doc.data()['receiverId'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки отправленных заявок: $e');
    }
  }

  void _setupPresenceListener() {
    _presenceListener = _realtimeDatabase.ref('presence').onValue.listen((event) {
      final updatedStatus = <String, Map<String, dynamic>>{};
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((userId, userData) {
          if (userData is Map && userData.containsKey('isOnline') && userData.containsKey('lastSeen')) {
            updatedStatus[userId as String] = {
              'isOnline': userData['isOnline'] as bool? ?? false,
              'lastSeen': userData['lastSeen'] as int? ?? 0,
            };
          }
        });
      }
      if (mounted) {
        setState(() {
          _onlineStatus = updatedStatus;
          debugPrint("statistic.dart: _onlineStatus обновлен: $_onlineStatus");
        });
      }
    }, onError: (error) {
      debugPrint("statistic.dart: Ошибка при получении статуса присутствия: $error");
    });
  }

  Future<void> _setupRequestListener() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _firestore
          .collection('friend_requests')
          .where('receiverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _pendingRequestsCount = snapshot.docs.length;
          });
        }
      }, onError: (error) {
        debugPrint("statistic.dart: Ошибка слушателя заявок: $error");
      });
    } catch (e) {
      debugPrint("statistic.dart: Ошибка настройки слушателя заявок: $e");
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final List<Future<Map<String, dynamic>?>> friendFutures = [];
      final friendsSnapshot = await _firestore
          .collection('friends')
          .where('users', arrayContains: user.uid)
          .get();

      for (var doc in friendsSnapshot.docs) {
        final friendId = doc.data()['users'].firstWhere((id) => id != user.uid);
        friendFutures.add(
          _firestore.collection('users').doc(friendId).get().then((userDoc) {
            if (userDoc.exists) {
              return {
                ...userDoc.data()!,
                'id': friendId,
                'docId': doc.id,
                'type': 'friend',
              };
            }
            return null;
          }),
        );
      }

      final List<Map<String, dynamic>?> loadedFriendsWithNulls = await Future.wait(friendFutures);
      final List<Map<String, dynamic>> loadedFriends = loadedFriendsWithNulls.whereType<Map<String, dynamic>>().toList();

      if (mounted) {
        setState(() {
          _friends = loadedFriends;
        });
      }

      final List<Future<Map<String, dynamic>?>> requestFutures = [];
      final requestsSnapshot = await _firestore
          .collection('friend_requests')
          .where('receiverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestsSnapshot.docs) {
        requestFutures.add(
          _firestore.collection('users').doc(doc.data()['senderId']).get().then((senderDoc) {
            if (senderDoc.exists) {
              return {
                ...senderDoc.data()!,
                'id': doc.data()['senderId'],
                'requestId': doc.id,
                'type': 'request',
              };
            }
            return null;
          }),
        );
      }

      final List<Map<String, dynamic>?> loadedRequestsWithNulls = await Future.wait(requestFutures);
      final List<Map<String, dynamic>> loadedRequests = loadedRequestsWithNulls.whereType<Map<String, dynamic>>().toList();

      if (mounted) {
        setState(() {
          _requests = loadedRequests;
        });
      }

      await _loadFriendsStreaks();
    } catch (e) {
      if (mounted) SnackBarService.showSnackBar(context, 'Ошибка загрузки данных: $e', true);
      debugPrint('statistic.dart: Ошибка загрузки данных: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getOnlineStatusText(String userId) {
    final statusData = _onlineStatus[userId];
    if (statusData == null) {
      return 'Загрузка статуса...';
    }

    final isOnline = statusData['isOnline'] as bool? ?? false;
    final lastSeenTimestamp = statusData['lastSeen'] as int? ?? 0;

    if (isOnline) {
      return 'В сети';
    } else if (lastSeenTimestamp > 0) {
      final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp);
      final now = DateTime.now();
      final difference = now.difference(lastSeenDate);

      if (difference.inMinutes < 1) {
        return 'Не в сети (только что)';
      } else if (difference.inHours < 1) {
        return 'Не в сети (${difference.inMinutes} мин. назад)';
      } else if (difference.inHours < 24) {
        return 'Не в сети (${difference.inHours} ч. назад)';
      } else if (difference.inDays < 7) {
        return 'Не в сети (${difference.inDays} дн. назад)';
      } else {
        return 'Не в сети (${DateFormat('dd.MM.yyyy HH:mm').format(lastSeenDate)})';
      }
    }
    return 'Не в сети (статус недоступен)';
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/background.svg',
                fit: BoxFit.cover,
              ),
            ),
            const Center(child: Text('')),
          ],
        ),
      );
    }

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
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
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
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => setState(() {
                                  _selectedTab = 0;
                                  _searchController.clear();
                                  _searchResults = [];
                                }),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedTab == 0 ? primaryColor : Colors.transparent,
                                  foregroundColor: _selectedTab == 0 ? Colors.white : Colors.grey,
                                  textStyle: const TextStyle(fontSize: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: const Text('Друзья'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => setState(() {
                                      _selectedTab = 1;
                                      _searchController.clear();
                                      _searchResults = [];
                                    }),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _selectedTab == 1 ? primaryColor : Colors.transparent,
                                      foregroundColor: _selectedTab == 1 ? Colors.white : Colors.grey,
                                      textStyle: const TextStyle(fontSize: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: const Text('Заявки'),
                                  ),
                                  if (_pendingRequestsCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _pendingRequestsCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_selectedTab == 0) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Поиск по нику',
                              prefixIcon: Icon(Icons.search, size: 20),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 14),
                            onChanged: (query) => _searchUsers(query),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
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
                          : _selectedTab == 0
                              ? _buildFriendsTab()
                              : _buildRequestsTab(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) => _buildSearchResultItem(_searchResults[index]),
      );
    }
    return _friends.isEmpty
        ? const Center(child: Text('У вас пока нет друзей', style: TextStyle(fontSize: 14)))
        : ListView.builder(
            itemCount: _friends.length,
            itemBuilder: (context, index) => _buildFriendItem(_friends[index]),
          );
  }

  Widget _buildRequestsTab() {
    return _requests.isEmpty
        ? const Center(child: Text('Нет новых заявок', style: TextStyle(fontSize: 14)))
        : ListView.builder(
            itemCount: _requests.length,
            itemBuilder: (context, index) => _buildRequestItem(_requests[index]),
          );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    final statusData = _onlineStatus[friend['id']];
    final isOnline = statusData?['isOnline'] as bool? ?? false;
    final avatarId = friend['avatarId'] as int?;
    final avatar = avatarId != null
        ? _availableAvatars.firstWhere(
            (a) => a['id'] == avatarId,
            orElse: () => _availableAvatars[0],
          )
        : null;
    final streak = _friendsStreaks[friend['id']] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: avatar != null ? AssetImage(avatar['image']) : null,
              child: avatar == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          friend['nickname'] ?? 'Без ника',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          _getOnlineStatusText(friend['id']),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      streak.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.favorite, color: Colors.red, size: 16),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _removeFriend(friend['docId']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
    final statusData = _onlineStatus[request['id']];
    final isOnline = statusData?['isOnline'] as bool? ?? false;
    final avatarId = request['avatarId'] as int?;
    final avatar = avatarId != null
        ? _availableAvatars.firstWhere(
            (a) => a['id'] == avatarId,
            orElse: () => _availableAvatars[0],
          )
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: avatar != null ? AssetImage(avatar['image']) : null,
              child: avatar == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          request['nickname'] ?? 'Без ника',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          _getOnlineStatusText(request['id']),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green, size: 20),
              onPressed: () => _respondToRequest(request['requestId'], true),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: () => _respondToRequest(request['requestId'], false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> user) {
    final statusData = _onlineStatus[user['id']];
    final isOnline = statusData?['isOnline'] as bool? ?? false;
    final isFriend = _friends.any((friend) => friend['id'] == user['id']);
    final hasPendingRequest = _requests.any((req) => req['id'] == user['id']);
    final hasSentRequest = _sentRequests.contains(user['id']);
    final avatarId = user['avatarId'] as int?;
    final avatar = avatarId != null
        ? _availableAvatars.firstWhere(
            (a) => a['id'] == avatarId,
            orElse: () => _availableAvatars[0],
          )
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: avatar != null ? AssetImage(avatar['image']) : null,
              child: avatar == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          user['nickname'] ?? 'Без ника',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          _getOnlineStatusText(user['id']),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isFriend
            ? const Text('Уже друзья', style: TextStyle(color: Colors.green, fontSize: 12))
            : hasPendingRequest
                ? const Text('Запрос получен', style: TextStyle(color: Colors.orange, fontSize: 12))
                : hasSentRequest
                    ? const Text('Заявка отправлена', style: TextStyle(color: Colors.blue, fontSize: 12))
                    : IconButton(
                        icon: const Icon(Icons.person_add, size: 20),
                        onPressed: () => _sendFriendRequest(user['id']),
                      ),
      ),
    );
  }

  Future<void> _sendFriendRequest(String userId) async {
    if (_sentRequests.contains(userId)) {
      SnackBarService.showSnackBar(context, 'Вы уже отправили заявку этому пользователю', true);
      return;
    }

    try {
      await _firestore.collection('friend_requests').add({
        'senderId': _auth.currentUser!.uid,
        'receiverId': userId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _sentRequests.add(userId);
        });
      }

      SnackBarService.showSnackBar(context, 'Заявка отправлена', false);
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка: $e', true);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: query)
          .where('nickname', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      if (mounted) {
        setState(() {
          _searchResults = snapshot.docs
              .where((doc) => doc.id != _auth.currentUser?.uid)
              .map((doc) => {
                    ...doc.data(),
                    'id': doc.id,
                  })
              .toList();
        });
      }
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка поиска: $e', true);
    }
  }

  Future<void> _removeFriend(String docId) async {
    try {
      await _firestore.collection('friends').doc(docId).delete();
      await _loadData();
      SnackBarService.showSnackBar(context, 'Друг удален', false);
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка: $e', true);
    }
  }

  Future<void> _respondToRequest(String requestId, bool accept) async {
    try {
      final requestDoc = await _firestore.collection('friend_requests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Заявка не найдена');
      }

      final data = requestDoc.data()!;
      final currentUserId = _auth.currentUser!.uid;

      if (data['receiverId'] != currentUserId) {
        throw Exception('Нет прав для выполнения этого действия');
      }

      if (accept) {
        await _firestore.collection('friends').add({
          'users': [data['senderId'], data['receiverId']],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _firestore.collection('friend_requests').doc(requestId).update({
        'status': accept ? 'accepted' : 'rejected',
      });

      await _loadData();
      SnackBarService.showSnackBar(
        context,
        accept ? 'Заявка принята' : 'Заявка отклонена',
        false,
      );
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка: $e', true);
    }
  }
}