import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connecthub/service/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_user.dart';
import 'conversation_page.dart';
import 'find_users_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) return '';

    final date = value.toDate().toLocal();
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
    }

    if (now.difference(date).inDays == 1) return 'Yesterday';

    return '${date.day}/${date.month}/${date.year}';
  }

  void _openFindUsers() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FindUsersPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Please log in to view messages.'));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Messages',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chat with people you connect with',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'New message',
                    onPressed: _openFindUsers,
                    icon: const Icon(Icons.edit_square),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: ChatService.instance.getChatsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load conversations.'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.toList();

                  docs.sort((a, b) {
                    final aTime = a.data()['lastMessageAt'];
                    final bTime = b.data()['lastMessageAt'];

                    final aMillis = aTime is Timestamp
                        ? aTime.millisecondsSinceEpoch
                        : 0;
                    final bMillis = bTime is Timestamp
                        ? bTime.millisecondsSinceEpoch
                        : 0;

                    return bMillis.compareTo(aMillis);
                  });

                  if (docs.isEmpty) {
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
                                Icons.forum_outlined,
                                size: 44,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No conversations yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Find people and send your first message.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _openFindUsers,
                              icon: const Icon(Icons.person_search),
                              label: const Text('Find people'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final participants = List<String>.from(
                        data['participants'] ?? const [],
                      );

                      final otherUids = participants
                          .where((participant) => participant != uid)
                          .toList();

                      if (otherUids.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final otherUid = otherUids.first;

                      return StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: ChatService.instance.getUserStream(otherUid),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const SizedBox.shrink();
                          }

                          final otherUser = ChatUser.fromMap(
                            userSnapshot.data!.id,
                            userSnapshot.data!.data()!,
                          );

                          final lastMessage =
                              data['lastMessage'] as String? ?? '';

                          if (_searchQuery.isNotEmpty &&
                              !otherUser.name.toLowerCase().contains(
                                    _searchQuery,
                                  ) &&
                              !otherUser.email.toLowerCase().contains(
                                    _searchQuery,
                                  ) &&
                              !lastMessage.toLowerCase().contains(
                                    _searchQuery,
                                  )) {
                            return const SizedBox.shrink();
                          }

                          return Material(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ConversationPage(
                                      chatId: doc.id,
                                      otherUser: otherUser,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 27,
                                      backgroundColor:
                                          colors.primaryContainer,
                                      backgroundImage:
                                          otherUser.photoUrl.isNotEmpty
                                              ? NetworkImage(
                                                  otherUser.photoUrl,
                                                )
                                              : null,
                                      child: otherUser.photoUrl.isEmpty
                                          ? Text(
                                              otherUser.name.isNotEmpty
                                                  ? otherUser.name[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color: colors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            otherUser.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            lastMessage.isEmpty
                                                ? 'Start a conversation'
                                                : '${data['lastSenderId'] == uid ? 'You: ' : ''}$lastMessage',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color:
                                                  colors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatTime(data['lastMessageAt']),
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}