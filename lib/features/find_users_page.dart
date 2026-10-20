import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connecthub/service/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/chat_user.dart';
import 'conversation_page.dart';

class FindUsersPage extends StatefulWidget {
  const FindUsersPage({super.key});

  @override
  State<FindUsersPage> createState() => _FindUsersPageState();
}

class _FindUsersPageState extends State<FindUsersPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
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
        title: const Text(
          'Find people',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _query = value.trim().toLowerCase());
                  },
                  decoration: InputDecoration(
                    hintText: 'Search people by name or email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
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
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: ChatService.instance.getUsersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Could not load users.'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!.docs
                        .where((doc) => doc.id != myUid)
                        .map((doc) => ChatUser.fromMap(doc.id, doc.data()))
                        .where((user) {
                          return user.name.toLowerCase().contains(_query) ||
                              user.email.toLowerCase().contains(_query) ||
                              user.nickname.toLowerCase().contains(_query);
                        })
                        .toList()
                      ..sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                              b.name.toLowerCase(),
                            ),
                      );

                    if (users.isEmpty) {
                      return Center(
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
                                Icons.person_search_rounded,
                                size: 42,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No users found.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = users[index];

                        return Material(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              try {
                                final chatId = await ChatService.instance
                                    .openChat(user.uid);

                                if (!context.mounted) return;

                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ConversationPage(
                                      chatId: chatId,
                                      otherUser: user,
                                    ),
                                  ),
                                );
                              } catch (error) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open chat: $error'),
                                  ),
                                );
                              }
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
                                    radius: 25,
                                    backgroundColor: colors.primaryContainer,
                                    backgroundImage: user.photoUrl.isNotEmpty
                                        ? NetworkImage(user.photoUrl)
                                        : null,
                                    child: user.photoUrl.isEmpty
                                        ? Text(
                                            user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: colors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
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
                                          user.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15.5,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          user.nickname.isNotEmpty
                                              ? '@${user.nickname}'
                                              : user.email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: colors.onPrimaryContainer,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}