import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connecthub/service/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_user.dart';

class ConversationPage extends StatefulWidget {
  final String chatId;
  final ChatUser otherUser;

  const ConversationPage({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _sending = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await ChatService.instance.sendMessage(
        chatId: widget.chatId,
        text: text,
      );

      if (!mounted) return;
      _messageController.clear();
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message could not be sent. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      debugPrint('Send message error: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return 'Sending...';

    final date = value.toDate().toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    if (myUid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: colors.primaryContainer,
              backgroundImage: widget.otherUser.photoUrl.isNotEmpty
                  ? NetworkImage(widget.otherUser.photoUrl)
                  : null,
              child: widget.otherUser.photoUrl.isEmpty
                  ? Text(
                      widget.otherUser.name.isNotEmpty
                          ? widget.otherUser.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                    ),
                  ),
                  Text(
                    'ConnectHub',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ChatService.instance.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Could not load messages.'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.waving_hand_rounded,
                              size: 42,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Say hello to ${widget.otherUser.name}!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your conversation starts here.',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 18,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data();
                    final isMe = message['senderId'] == myUid;
                    final text = message['text'] as String? ?? '';
                    final time = _formatTime(message['createdAt']);

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.74,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? colors.primary
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 5),
                            bottomRight: Radius.circular(isMe ? 5 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color:
                                    isMe ? colors.onPrimary : colors.onSurface,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                color: isMe
                                    ? colors.onPrimary.withValues(alpha: 0.75)
                                    : colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
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

          // Message input bar
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5,
                        enabled: !_sending,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: colors.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send message',
                      onPressed: _sending ? null : _sendMessage,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}