import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowstate/services/colors.dart';
import 'package:flowstate/services/snackbar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  int _selectedTab = 0;
  int _pendingRequestsCount = 0;
  Map<String, bool> _onlineStatus = {};
  List<String> _sentRequests = [];

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser != null) {
      _loadData();
      _setupRequestListener();
      _setupOnlineStatusListener();
      _loadSentRequests();
    }
  }

  Future<void> _loadSentRequests() async {
    try {
      final snapshot = await _firestore
          .collection('friend_requests')
          .where('senderId', isEqualTo: _auth.currentUser!.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        _sentRequests = snapshot.docs.map((doc) => doc.data()['receiverId'] as String).toList();
      });
    } catch (e) {
      debugPrint('Ошибка загрузки отправленных заявок: $e');
    }
  }

  Future<void> _setupOnlineStatusListener() async {
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

  Future<void> _setupRequestListener() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _pendingRequestsCount = snapshot.docs.length;
      });
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load friends
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

      // Load requests
      final requestsSnapshot = await _firestore
          .collection('friend_requests')
          .where('receiverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      _requests = await Future.wait(
        requestsSnapshot.docs.map((doc) async {
          final senderDoc = await _firestore.collection('users').doc(doc.data()['senderId']).get();
          return {
            ...senderDoc.data()!,
            'id': doc.data()['senderId'],
            'requestId': doc.id,
            'type': 'request',
          };
        }),
      );
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка загрузки данных: $e', true);
    } finally {
      setState(() => _isLoading = false);
    }
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
              padding: const EdgeInsets.only(top: 16), // Отступ сверху
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
                            const SizedBox(width: 8), // Отступ между кнопками
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
                          const SizedBox(height: 8), // Отступ перед полем поиска
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
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24), // Нижний отступ для BottomNavigationBar
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
    final isOnline = _onlineStatus[friend['id']] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), // Уменьшен вертикальный отступ
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.2), // Прозрачный зеленый фон
        borderRadius: BorderRadius.circular(24), // Скругленные углы
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _getAvatarImage(friend['avatarId']),
              backgroundColor: friend['avatarId'] == null || (friend['avatarId'] != 1 && friend['avatarId'] != 2)
                  ? _getAvatarColor(friend['avatarId'])
                  : Colors.transparent,
              child: friend['avatarId'] == null || (friend['avatarId'] != 1 && friend['avatarId'] != 2)
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
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
          isOnline ? 'В сети' : 'Не в сети',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: () => _removeFriend(friend['docId']),
        ),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request) {
  final isOnline = _onlineStatus[request['id']] ?? false;

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), // Уменьшен вертикальный отступ
    decoration: BoxDecoration(
      color: secondaryColor.withOpacity(0.2), // Прозрачный зеленый фон
      borderRadius: BorderRadius.circular(24), // Скругленные углы
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: _getAvatarImage(request['avatarId']),
            backgroundColor: request['avatarId'] == null || (request['avatarId'] != 1 && request['avatarId'] != 2)
                ? _getAvatarColor(request['avatarId'])
                : Colors.transparent,
            child: request['avatarId'] == null || (request['avatarId'] != 1 && request['avatarId'] != 2)
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
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
        isOnline ? 'В сети' : 'Не в сети',
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
    final isOnline = _onlineStatus[user['id']] ?? false;
    final isFriend = _friends.any((friend) => friend['id'] == user['id']);
    final hasPendingRequest = _requests.any((req) => req['id'] == user['id']);
    final hasSentRequest = _sentRequests.contains(user['id']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _getAvatarImage(user['avatarId']),
              backgroundColor: user['avatarId'] == null || (user['avatarId'] != 1 && user['avatarId'] != 2)
                  ? _getAvatarColor(user['avatarId'])
                  : Colors.transparent,
              child: user['avatarId'] == null || (user['avatarId'] != 1 && user['avatarId'] != 2)
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
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
          isOnline ? 'В сети' : 'Не в сети',
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

  ImageProvider? _getAvatarImage(int? avatarId) {
    switch (avatarId) {
      case 1:
        return const AssetImage('assets/male.png');
      case 2:
        return const AssetImage('assets/female.png');
      default:
        return null;
    }
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

      setState(() {
        _sentRequests.add(userId);
      });

      SnackBarService.showSnackBar(context, 'Заявка отправлена', false);
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка: $e', true);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: query)
          .where('nickname', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      setState(() {
        _searchResults = snapshot.docs
            .where((doc) => doc.id != _auth.currentUser?.uid)
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
      });
    } catch (e) {
      SnackBarService.showSnackBar(context, 'Ошибка поиска: $e', true);
    }
  }

  Color _getAvatarColor(int? avatarId) {
    const defaultColor = Colors.grey;
    if (avatarId == null) return defaultColor;

    switch (avatarId) {
      case 3:
        return Colors.green;
      case 4:
        return Colors.yellow;
      case 5:
        return Colors.purple;
      case 6:
        return Colors.orange;
      default:
        return defaultColor;
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