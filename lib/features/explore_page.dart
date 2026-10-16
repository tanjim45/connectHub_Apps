
import 'package:flutter/material.dart';
import 'package:connecthub/models/post_model.dart';
import 'package:connecthub/models/user_model.dart';
import 'package:connecthub/service/post_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController =
      TextEditingController();

  List<PostModel> _posts = [];

  final Map<int, UserModel> _userCache = {};
  final Map<int, Future<UserModel>> _userRequests = {};

  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // API থেকে user information আনা এবং cache করা
  Future<UserModel> _getUser(int userId) {
    if (_userCache.containsKey(userId)) {
      return Future.value(_userCache[userId]!);
    }

    if (_userRequests.containsKey(userId)) {
      return _userRequests[userId]!;
    }

    final request = PostService.fetchUser(userId);
    _userRequests[userId] = request;

    return request.then((user) {
      _userCache[userId] = user;
      _userRequests.remove(userId);
      return user;
    }).catchError((error) {
      _userRequests.remove(userId);
      throw error;
    });
  }

  // API থেকে posts load করা
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await PostService.fetchPosts(
        page: 1,
        limit: 30,
      );

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Posts load করা যায়নি। Internet connection পরীক্ষা করো।';
        _isLoading = false;
      });
    }
  }

  // Search অনুযায়ী posts filter করা
  List<PostModel> get _filteredPosts {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return _posts;

    return _posts.where((post) {
      return post.title.toLowerCase().contains(query) ||
          post.body.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final posts = _filteredPosts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Explore posts...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: colors.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildContent(posts, colors),
        ),
      ],
    );
  }

  Widget _buildContent(
    List<PostModel> posts,
    ColorScheme colors,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (posts.isEmpty) {
      return const Center(
        child: Text('কোনো matching post পাওয়া যায়নি।'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width >= 1100
            ? 4
            : width >= 750
                ? 3
                : width >= 450
                    ? 2
                    : 1;

        return RefreshIndicator(
          onRefresh: _loadPosts,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 1 ? 1.35 : 0.85,
            ),
            itemBuilder: (context, index) {
              final post = posts[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: colors.outlineVariant,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (sheetContext) {
                        return SafeArea(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              20, 8, 20, 32,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<UserModel>(
                                  future: _getUser(post.userId),
                                  builder: (context, snapshot) {
                                    final user = snapshot.data;

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            colors.primaryContainer,
                                        child: Text(
                                          user != null &&
                                                  user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: colors
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        user?.name ?? 'Loading user...',
                                      ),
                                      subtitle: user != null
                                          ? Text('@${user.username}')
                                          : null,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  post.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(post.body),
                                const SizedBox(height: 16),
                                Text(
                                  'Post #${post.id}',
                                  style: TextStyle(
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Post author's name and avatar
                        Row(
                          children: [
                            FutureBuilder<UserModel>(
                              future: _getUser(post.userId),
                              builder: (context, snapshot) {
                                final user = snapshot.data;

                                return CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      colors.primaryContainer,
                                  child: user == null
                                      ? Icon(
                                          Icons.person_outline_rounded,
                                          color:
                                              colors.onPrimaryContainer,
                                        )
                                      : Text(
                                          user.name.isNotEmpty
                                              ? user.name[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: colors
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FutureBuilder<UserModel>(
                                future: _getUser(post.userId),
                                builder: (context, snapshot) {
                                  final user = snapshot.data;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.name ??
                                            'Loading user...',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (user != null)
                                        Text(
                                          '@${user.username}',
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Post title
                        Text(
                          post.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Post body
                        Expanded(
                          child: Text(
                            post.body,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.explore_outlined,
                              size: 18,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Explore',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
