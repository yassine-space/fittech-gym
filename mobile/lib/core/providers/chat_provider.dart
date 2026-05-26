// lib/core/providers/chat_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class ConversationUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profilePhoto;

  ConversationUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profilePhoto,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory ConversationUser.fromJson(Map<String, dynamic> j) =>
      ConversationUser(
        id: j['id'] ?? '',
        firstName: j['first_name'] ?? '',
        lastName: j['last_name'] ?? '',
        email: j['email'] ?? '',
        profilePhoto: j['profile_photo'],
      );
}

class ConversationParticipant {
  final String id;
  final ConversationUser user;

  ConversationParticipant({required this.id, required this.user});

  factory ConversationParticipant.fromJson(Map<String, dynamic> j) =>
      ConversationParticipant(
        id: j['id'] ?? '',
        user: ConversationUser.fromJson(
          (j['user'] is Map<String, dynamic>) ? j['user'] : {},
        ),
      );
}

class LastMessage {
  final String content;
  final DateTime createdAt;
   bool isRead;

  LastMessage({
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory LastMessage.fromJson(Map<String, dynamic> j) => LastMessage(
        content: j['content'] ?? '',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
        isRead: j['is_read'] ?? false,
      );
}

class Conversation {
  final String id;
  final ConversationParticipant coach;
  final ConversationParticipant membre;
  final DateTime createdAt;
  final LastMessage? lastMessage;

  Conversation({
    required this.id,
    required this.coach,
    required this.membre,
    required this.createdAt,
    this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] ?? '',
        coach: ConversationParticipant.fromJson(
          j['coach'] is Map<String, dynamic> ? j['coach'] : {},
        ),
        membre: ConversationParticipant.fromJson(
          j['membre'] is Map<String, dynamic> ? j['membre'] : {},
        ),
        createdAt:
            DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
        lastMessage: j['last_message'] != null
            ? LastMessage.fromJson(j['last_message'])
            : null,
      );

  /// Returns the *other* participant's user given the coach's user id
  ConversationUser otherUser(String myUserId) =>
      coach.user.id == myUserId ? membre.user : coach.user;
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageType; // text | image | file
  final String content;
  bool isRead;
  final DateTime? deletedAt;
  final DateTime createdAt;
  bool isOptimistic; // true while not yet confirmed by server

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    required this.content,
    required this.isRead,
    this.deletedAt,
    required this.createdAt,
    this.isOptimistic = false,
  });

  bool get isDeleted => deletedAt != null;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] ?? '',
        conversationId: j['conversation']?.toString() ?? '',
        senderId: j['sender']?.toString() ?? '',
        messageType: j['message_type'] ?? 'text',
        content: j['content'] ?? '',
        isRead: j['is_read'] ?? false,
        deletedAt: j['deleted_at'] != null
            ? DateTime.tryParse(j['deleted_at'])
            : null,
        createdAt:
            DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatProvider
// ─────────────────────────────────────────────────────────────────────────────

class ChatProvider extends ChangeNotifier {
  // ── Config ─────────────────────────────────────────────────────────────────
  static const _baseHttp = 'http://localhost:8000'; // adjust for prod
  static const _baseWs = 'ws://localhost:8000';

  // ── Conversations ──────────────────────────────────────────────────────────
  List<Conversation> _conversations = [];
  List<Conversation> get conversations => _conversations;

  bool _convLoading = false;
  bool get convLoading => _convLoading;

  String? _convError;
  String? get convError => _convError;

  // ── Messages (active conversation) ────────────────────────────────────────
  String? _activeConvId;
  String? get activeConvId => _activeConvId;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _msgLoading = false;
  bool get msgLoading => _msgLoading;

  String? _msgError;
  String? get msgError => _msgError;

  // ── Online presence ────────────────────────────────────────────────────────
  final Map<String, bool> _onlineStatus = {};
  bool isOnline(String userId) => _onlineStatus[userId] ?? false;

  // ── WebSocket ──────────────────────────────────────────────────────────────
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  bool _wsConnected = false;
  bool get wsConnected => _wsConnected;

  // ── Current user ───────────────────────────────────────────────────────────
  String? _myUserId;
  String? get myUserId => _myUserId;

  // ─────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _myUserId = prefs.getString('user_id');
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Conversations
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadConversations() async {
    _convLoading = true;
    _convError = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$_baseHttp/conversations/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        _conversations =
            data.map((j) => Conversation.fromJson(j)).toList();
        // Sort: newest last_message first
        _conversations.sort((a, b) {
          final aTime =
              a.lastMessage?.createdAt ?? a.createdAt;
          final bTime =
              b.lastMessage?.createdAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
      } else {
        _convError = 'Failed to load conversations (${res.statusCode})';
      }
    } catch (e) {
      _convError = 'Network error: $e';
    } finally {
      _convLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Messages (REST – initial load)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadMessages(String conversationId) async {
    if (_activeConvId != conversationId) {
      _messages = [];
    }
    _activeConvId = conversationId;
    _msgLoading = true;
    _msgError = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse(
            '$_baseHttp/conversations/$conversationId/messages/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        _messages =
            data.map((j) => ChatMessage.fromJson(j)).toList();
      } else {
        _msgError = 'Failed to load messages (${res.statusCode})';
      }
    } catch (e) {
      _msgError = 'Network error: $e';
    } finally {
      _msgLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WebSocket
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> connectWebSocket(String conversationId) async {
    await disconnectWebSocket();

    final token = await _getToken();
    if (token == null) return;

    final uri = Uri.parse(
        '$_baseWs/ws/chat/$conversationId/?token=$token');
    _channel = WebSocketChannel.connect(uri);
    _wsConnected = true;
    notifyListeners();

    _wsSub = _channel!.stream.listen(
      _onWsMessage,
      onDone: _onWsDone,
      onError: _onWsError,
      cancelOnError: false,
    );
  }

  void _onWsMessage(dynamic raw) {
    try {
      final data = json.decode(raw as String) as Map<String, dynamic>;
      final action = data['action'] as String?;

      switch (action) {
        case 'new_message':
          _handleNewMessage(data);
          break;
        case 'messages_read':
          _handleMessagesRead(data);
          break;
        case 'message_deleted':
          _handleMessageDeleted(data);
          break;
        case 'user_status':
          _handleUserStatus(data);
          break;
      }
    } catch (_) {}
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    final msgId = data['message_id'] as String?;
    if (msgId == null) return;

    // Remove matching optimistic message (same sender + content, no real id)
    _messages.removeWhere((m) =>
        m.isOptimistic &&
        m.senderId == data['sender_id'] &&
        m.content == (data['content'] ?? ''));

    // Add the confirmed message
    _messages.add(ChatMessage(
      id: msgId,
      conversationId: _activeConvId ?? '',
      senderId: data['sender_id'] ?? '',
      messageType: data['message_type'] ?? 'text',
      content: data['content'] ?? '',
      isRead: false,
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ??
          DateTime.now(),
    ));

    // Update last message in conversation list
    _updateConvLastMessage(data);
    notifyListeners();
  }

  void _handleMessagesRead(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    if (userId == null || userId == _myUserId) return;
    for (final m in _messages) {
      m.isRead = true;
    }
    notifyListeners();
  }

  void _handleMessageDeleted(Map<String, dynamic> data) {
    final msgId = data['message_id'] as String?;
    if (msgId == null) return;
    final idx = _messages.indexWhere((m) => m.id == msgId);
    if (idx != -1) {
      // Mark as deleted locally
      final old = _messages[idx];
      _messages[idx] = ChatMessage(
        id: old.id,
        conversationId: old.conversationId,
        senderId: old.senderId,
        messageType: old.messageType,
        content: old.content,
        isRead: old.isRead,
        deletedAt: DateTime.now(),
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }

  void _handleUserStatus(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    final online = data['online'] as bool? ?? false;
    if (userId != null) {
      _onlineStatus[userId] = online;
      notifyListeners();
    }
  }

  void _onWsDone() {
    _wsConnected = false;
    notifyListeners();
  }

  void _onWsError(dynamic err) {
    _wsConnected = false;
    notifyListeners();
  }

  void _updateConvLastMessage(Map<String, dynamic> data) {
    final convId = _activeConvId;
    if (convId == null) return;
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx == -1) return;
    final old = _conversations[idx];
    _conversations[idx] = Conversation(
      id: old.id,
      coach: old.coach,
      membre: old.membre,
      createdAt: old.createdAt,
      lastMessage: LastMessage(
        content: data['content'] ?? '',
        createdAt:
            DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
        isRead: false,
      ),
    );
    // Re-sort
    _conversations.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? a.createdAt;
      final bTime = b.lastMessage?.createdAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Send / Delete via WebSocket
  // ─────────────────────────────────────────────────────────────────────────

  void sendMessage(String content) {
    if (content.trim().isEmpty || !_wsConnected) return;

    // Optimistic insert
    final optimistic = ChatMessage(
      id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _activeConvId ?? '',
      senderId: _myUserId ?? '',
      messageType: 'text',
      content: content.trim(),
      isRead: false,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );
    _messages.add(optimistic);
    notifyListeners();

    _channel?.sink.add(json.encode({
      'action': 'send_message',
      'message_type': 'text',
      'content': content.trim(),
    }));
  }

  void markRead() {
    if (!_wsConnected) return;
    _channel?.sink.add(json.encode({'action': 'mark_read'}));
  }

  void deleteMessage(String messageId) {
    if (!_wsConnected) return;
    _channel?.sink
        .add(json.encode({'action': 'delete_message', 'message_id': messageId}));
  }

  Future<void> disconnectWebSocket() async {
    await _wsSub?.cancel();
    _wsSub = null;
    await _channel?.sink.close();
    _channel = null;
    _wsConnected = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Unread count helpers
  // ─────────────────────────────────────────────────────────────────────────

  int get totalUnread {
    int count = 0;
    for (final c in _conversations) {
      if (c.lastMessage != null && !c.lastMessage!.isRead) count++;
    }
    return count;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }
}