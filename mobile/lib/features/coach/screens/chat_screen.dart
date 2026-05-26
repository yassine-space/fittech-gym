// lib/features/coach/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/providers/chat_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kOrange  = Color(0xFFD44820);
const _kNavy    = Color(0xFF1C1C1C);
const _kBg      = Color(0xFFF5EDE8);
const _kGrey    = Color(0xFF9A7060);
const _kWhite   = Colors.white;
const _kBubbleMe   = Color(0xFFD44820);
const _kBubbleThem = Color(0xFFFFFFFF);

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final can = _msgCtrl.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ChatProvider>();
      await provider.loadMessages(widget.conversation.id);
      await provider.connectWebSocket(widget.conversation.id);
      provider.markRead();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    context.read<ChatProvider>().disconnectWebSocket();
    super.dispose();
  }

  void _scrollToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (animated) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(text);
    _msgCtrl.clear();
    _scrollToBottom(animated: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final myId = provider.myUserId ?? '';
        final other = widget.conversation.otherUser(myId);
        final isOnline = provider.isOnline(other.id);
        final msgs =
            provider.messages.where((m) => !m.isDeleted).toList();

        // Scroll to bottom when new message arrives
        if (msgs.isNotEmpty) _scrollToBottom(animated: true);

        return Scaffold(
          backgroundColor: _kBg,
          appBar: _buildAppBar(other, isOnline, provider),
          body: Column(
            children: [
              // Connection banner
              if (!provider.wsConnected && provider.messages.isNotEmpty)
                _ConnectionBanner(
                  onRetry: () =>
                      provider.connectWebSocket(widget.conversation.id),
                ),

              // Messages list
              Expanded(
                child: _buildMessageList(msgs, myId, provider),
              ),

              // Input bar
              _buildInputBar(provider),
            ],
          ),
        );
      },
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      ConversationUser other, bool isOnline, ChatProvider provider) {
    return AppBar(
      backgroundColor: _kWhite,
      elevation: 0,
      leadingWidth: 40,
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_ios_rounded, color: _kNavy, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _kOrange,
                child: Text(
                  other.initials,
                  style: const TextStyle(
                      color: _kWhite,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3DB87A),
                      shape: BoxShape.circle,
                      border: Border.all(color: _kWhite, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                other.fullName,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kNavy),
              ),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 11,
                  color: isOnline
                      ? const Color(0xFF3DB87A)
                      : _kGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone_outlined, color: _kNavy, size: 20),
          onPressed: () {}, // placeholder
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────
  Widget _buildMessageList(
      List<ChatMessage> msgs, String myId, ChatProvider provider) {
    if (provider.msgLoading && msgs.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: _kOrange));
    }
    if (provider.msgError != null && msgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: _kOrange),
            const SizedBox(height: 8),
            Text(provider.msgError!,
                style: const TextStyle(color: _kGrey),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  provider.loadMessages(widget.conversation.id),
              style: ElevatedButton.styleFrom(backgroundColor: _kOrange),
              child: const Text('Retry',
                  style: TextStyle(color: _kWhite)),
            ),
          ],
        ),
      );
    }
    if (msgs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, size: 56, color: _kGrey),
            SizedBox(height: 10),
            Text('No messages yet',
                style: TextStyle(
                    color: _kNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            SizedBox(height: 4),
            Text('Send the first message!',
                style: TextStyle(color: _kGrey, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: msgs.length,
      itemBuilder: (_, i) {
        final msg = msgs[i];
        final isMe = msg.senderId == myId;
        final showDate = i == 0 ||
            !_sameDay(msgs[i - 1].createdAt, msg.createdAt);

        return Column(
          children: [
            if (showDate) _DateDivider(date: msg.createdAt),
            _MessageBubble(
              message: msg,
              isMe: isMe,
              onLongPress: isMe
                  ? () => _showDeleteDialog(context, msg, provider)
                  : null,
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _showDeleteDialog(
      BuildContext context, ChatMessage msg, ChatProvider provider) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: _kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0D0C8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  msg.content,
                  style: const TextStyle(color: _kNavy, fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.deleteMessage(msg.id);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete message'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    foregroundColor: _kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: _kGrey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar(ChatProvider provider) {
    return Container(
      color: _kWhite,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 1,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle:
                        TextStyle(color: Color(0xFFD1B8A8), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _canSend ? _kOrange : const Color(0xFFE0D0C8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _canSend ? _sendMessage : null,
                icon: const Icon(Icons.send_rounded,
                    color: _kWhite, size: 20),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _kBubbleMe : _kBubbleThem,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? _kWhite : _kNavy,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? _kWhite.withOpacity(0.7)
                              : const Color(0xFFBBA89A),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isOptimistic
                              ? Icons.access_time_rounded
                              : message.isRead
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                          size: 13,
                          color: message.isRead
                              ? const Color(0xFF9EECD4)
                              : _kWhite.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = now.difference(date).inDays == 0
        ? 'Today'
        : now.difference(date).inDays == 1
            ? 'Yesterday'
            : DateFormat('MMMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: Color(0xFFDBC8BC), thickness: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  color: _kGrey,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const Expanded(
              child: Divider(color: Color(0xFFDBC8BC), thickness: 0.8)),
        ],
      ),
    );
  }
}

// ─── Connection banner ────────────────────────────────────────────────────────
class _ConnectionBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _ConnectionBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3E0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 16, color: Color(0xFFE65100)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Reconnecting…',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text('Retry',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}