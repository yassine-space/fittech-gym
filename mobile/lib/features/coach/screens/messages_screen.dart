// lib/features/coach/screens/messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/providers/chat_provider.dart';
import 'chat_screen.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFD44820);
const _kNavy   = Color(0xFF1C1C1C);
const _kBg     = Color(0xFFF5EDE8);
const _kGrey   = Color(0xFF9A7060);
const _kWhite  = Colors.white;
const _kCard   = Color(0xFFEFDDD5);

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final convs = _filtered(provider.conversations, provider);

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(provider),
                const SizedBox(height: 12),
                _buildSearch(provider),
                const SizedBox(height: 8),
                Expanded(child: _buildBody(provider, convs)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(ChatProvider provider) {
    final unread = provider.totalUnread;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MESSAGES',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _kNavy,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Conversations with your members',
                  style: TextStyle(fontSize: 12, color: _kGrey),
                ),
              ],
            ),
          ),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unread unread',
                style: const TextStyle(
                  color: _kWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────
  Widget _buildSearch(ChatProvider provider) {
    if (provider.conversations.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search members…',
            hintStyle:
                const TextStyle(color: Color(0xFFD1B8A8), fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                color: _kOrange, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: _kGrey),
                    onPressed: () =>
                        setState(() {
                          _query = '';
                          _searchCtrl.clear();
                        }),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  List<Conversation> _filtered(
      List<Conversation> all, ChatProvider provider) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    final myId = provider.myUserId ?? '';
    return all.where((c) {
      final other = c.otherUser(myId);
      return other.fullName.toLowerCase().contains(q) ||
          other.email.toLowerCase().contains(q);
    }).toList();
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(ChatProvider provider, List<Conversation> convs) {
    if (provider.convLoading && provider.conversations.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: _kOrange));
    }
    if (provider.convError != null && provider.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _kOrange),
            const SizedBox(height: 8),
            Text(provider.convError!,
                style: const TextStyle(color: _kGrey),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.loadConversations(),
              style: ElevatedButton.styleFrom(backgroundColor: _kOrange),
              child: const Text('Retry',
                  style: TextStyle(color: _kWhite)),
            ),
          ],
        ),
      );
    }
    if (provider.conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 60, color: _kGrey),
            SizedBox(height: 12),
            Text(
              'No conversations yet',
              style: TextStyle(
                  color: _kNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Conversations with assigned members\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kGrey, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (convs.isEmpty) {
      return Center(
        child: Text(
          'No results for "$_query"',
          style: const TextStyle(color: _kGrey, fontWeight: FontWeight.w600),
        ),
      );
    }

    return RefreshIndicator(
      color: _kOrange,
      onRefresh: () => provider.loadConversations(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: convs.length,
        itemBuilder: (_, i) => _ConvCard(
          conversation: convs[i],
          provider: provider,
        ),
      ),
    );
  }
}

// ─── Conversation card ────────────────────────────────────────────────────────
class _ConvCard extends StatelessWidget {
  final Conversation conversation;
  final ChatProvider provider;

  const _ConvCard({required this.conversation, required this.provider});

  static const _avatarColors = [
    Color(0xFF5A3826),
    Color(0xFF7A4A30),
    Color(0xFFD4956A),
    Color(0xFF8B4513),
    Color(0xFF6B3A2A),
  ];

  @override
  Widget build(BuildContext context) {
    final myId = provider.myUserId ?? '';
    final other = conversation.otherUser(myId);
    final colorIdx = other.fullName.hashCode.abs() % _avatarColors.length;
    final last = conversation.lastMessage;
    final hasUnread = last != null && !last.isRead;
    final isOnline = provider.isOnline(other.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(conversation: conversation),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasUnread ? _kWhite : _kCard,
            borderRadius: BorderRadius.circular(18),
            boxShadow: hasUnread
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Avatar + online dot
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _avatarColors[colorIdx],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        other.initials,
                        style: const TextStyle(
                            color: _kWhite,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3DB87A),
                          shape: BoxShape.circle,
                          border: Border.all(color: _kWhite, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Name + preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            other.fullName,
                            style: TextStyle(
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: _kNavy,
                            ),
                          ),
                        ),
                        if (last != null)
                          Text(
                            _formatTime(last.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: hasUnread ? _kOrange : _kGrey,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            last?.content ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread ? _kNavy : _kGrey,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: _kOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return DateFormat('h:mm a').format(dt);
    } else if (now.difference(dt).inDays < 7) {
      return DateFormat('EEE').format(dt);
    }
    return DateFormat('d MMM').format(dt);
  }
}