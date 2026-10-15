
import 'package:connecthub/features/user_info.dart';
import 'package:flutter/material.dart';

import 'package:connecthub/models/post_model.dart';
import 'package:connecthub/models/user_model.dart';
import 'package:connecthub/service/post_service.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final int pageSize = 10;
  int currentPage = 1;

  List<PostModel> apiPosts = [];

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  String? errorMessage;
  String? loadMoreError;

  final ScrollController _scrollController = ScrollController();

  final Map<int, UserModel> userCache = {};
  final Map<int, Future<UserModel>> userRequests = {};

  final Set<int> likedPostIds = {};
  final Map<int, int> likeCounts = {};

  final Map<int, List<String>> postComments = {};
  final Map<int, TextEditingController> commentControllers = {};

  final List<String> pageTitles = [
    'Home',
    'Explore',
    'Create Post',
    'Chat',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    loadPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    for (final controller in commentControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // Load more posts when scrolling
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      loadMorePosts();
    }
  }

  // Fetch first page from API
  Future<void> loadPosts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      loadMoreError = null;
      isLoadingMore = false;
      currentPage = 1;
      hasMore = true;
      apiPosts = [];
    });

    try {
      final posts = await PostService.fetchPosts(
        page: 1,
        limit: pageSize,
      );

      if (!mounted) return;

      setState(() {
        apiPosts = posts;
        currentPage = 1;
        hasMore = posts.length == pageSize;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Posts could not load. Check your internet.';
        isLoading = false;
      });
    }
  }

  // Infinite scrolling
  Future<void> loadMorePosts() async {
    if (isLoading ||
        isLoadingMore ||
        !hasMore ||
        loadMoreError != null) {
      return;
    }

    setState(() {
      isLoadingMore = true;
    });

    final nextPage = currentPage + 1;

    try {
      final newPosts = await PostService.fetchPosts(
        page: nextPage,
        limit: pageSize,
      );

      if (!mounted) return;

      setState(() {
        final existingIds = apiPosts.map((post) => post.id).toSet();

        final uniquePosts = newPosts
            .where((post) => !existingIds.contains(post.id))
            .toList();

        apiPosts.addAll(uniquePosts);

        currentPage = nextPage;
        hasMore = newPosts.length == pageSize;
        isLoadingMore = false;
        loadMoreError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingMore = false;
        loadMoreError = 'Could not load more posts.';
      });
    }
  }

  // Fetch and cache user information
  Future<UserModel> getUser(int userId) {
    if (userCache.containsKey(userId)) {
      return Future.value(userCache[userId]!);
    }

    if (userRequests.containsKey(userId)) {
      return userRequests[userId]!;
    }

    final request = PostService.fetchUser(userId);
    userRequests[userId] = request;

    return request.then((user) {
      userCache[userId] = user;
      userRequests.remove(userId);
      return user;
    }).catchError((error) {
      userRequests.remove(userId);
      throw error;
    });
  }

  // Like and unlike
  void toggleLike(PostModel post) {
    setState(() {
      if (likedPostIds.contains(post.id)) {
        likedPostIds.remove(post.id);
        likeCounts[post.id] =
            ((likeCounts[post.id] ?? 1) - 1).clamp(0, 999999);
      } else {
        likedPostIds.add(post.id);
        likeCounts[post.id] = (likeCounts[post.id] ?? 0) + 1;
      }
    });
  }

  // Add a comment
  void addComment(PostModel post) {
    final controller = commentControllers.putIfAbsent(
      post.id,
      () => TextEditingController(),
    );

    final text = controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      postComments.putIfAbsent(post.id, () => []);
      postComments[post.id]!.add(text);
      controller.clear();
    });

    FocusScope.of(context).unfocus();
  }

  // User avatar and profile information
  Widget _buildUserInfo(int userId) {
    return FutureBuilder<UserModel>(
      future: getUser(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE2ECFA),
                child: Icon(Icons.person, color: Color(0xFF2684FF)),
              ),
              const SizedBox(width: 12),
              const Text('Unknown user'),
            ],
          );
        }

        if (!snapshot.hasData) {
          return const Row(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading profile...'),
            ],
          );
        }

        final user = snapshot.data!;

        return Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFFDCEBFF),
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF1769C2),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.public,
              size: 19,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        );
      },
    );
  }

  // Modern post card
  Widget _buildPostCard(PostModel post) {
    final isLiked = likedPostIds.contains(post.id);
    final comments = postComments[post.id] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfo( userId: post.userId,
  getUser: getUser,),

            const SizedBox(height: 22),

            Text(
              post.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
            ),

            const SizedBox(height: 10),

            Text(
              post.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.75,
                  ),
            ),

            const SizedBox(height: 20),

            // Like and comment counts
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 16,
                  color: isLiked ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  '${likeCounts[post.id] ?? 0} likes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  '${comments.length} comments',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            const Divider(height: 28),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: 'Like',
                    color: isLiked ? Colors.red : null,
                    onTap: () => toggleLike(post),
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: 'Comment',
                    onTap: () {
                      FocusScope.of(context).requestFocus(
                        FocusNode(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Write your comment in the box below.',
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Comment input
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: commentControllers.putIfAbsent(
                      post.id,
                      () => TextEditingController(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => addComment(post),
                  tooltip: 'Send comment',
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),

            // Comments
            if (comments.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...comments.map(
                (comment) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 15,
                        child: Icon(Icons.person, size: 17),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(comment)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Home feed
  Widget _buildHomeContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 52),
              const SizedBox(height: 14),
              Text(errorMessage!),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: loadPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (apiPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dynamic_feed_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text('No posts found.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: loadPosts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadPosts,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        itemCount: apiPosts.length +
            ((isLoadingMore || loadMoreError != null || !hasMore) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == apiPosts.length) {
            if (isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (loadMoreError != null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Text(loadMoreError!),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => loadMoreError = null);
                          loadMorePosts();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!hasMore) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('🎉 You have seen all posts!'),
                ),
              );
            }
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: _buildPostCard(apiPosts[index]),
            ),
          );
        },
      ),
    );
  }

  // Placeholder pages
  Widget _buildSelectedPage() {
    if (selectedIndex == 0) {
      return _buildHomeContent();
    }

    final descriptions = [
      '',
      'Explore posts coming soon.',
      'Create Post feature coming soon.',
      'Chat feature coming soon.',
      'Profile feature coming soon.',
    ];

    final icons = [
      Icons.home_rounded,
      Icons.explore_rounded,
      Icons.add_box_rounded,
      Icons.chat_bubble_rounded,
      Icons.person_rounded,
    ];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icons[selectedIndex],
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            pageTitles[selectedIndex],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(descriptions[selectedIndex]),
        ],
      ),
    );
  }

  // Navigation item
  Widget _buildNavigationItem(
    int index,
    IconData icon,
    String label,
  ) {
    final selected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        selected: selected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: () {
          setState(() => selectedIndex = index);

          if (MediaQuery.of(context).size.width < 1000) {
            Navigator.of(context).maybePop();
          }
        },
      ),
    );
  }

  // Sidebar
  Widget _buildNavigationMenu() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.hub_rounded,
                  color: Color(0xFF2684FF),
                  size: 34,
                ),
                SizedBox(width: 10),
                Text(
                  'ConnectHub',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          _buildNavigationItem(0, Icons.home_rounded, 'Home'),
          _buildNavigationItem(1, Icons.explore_rounded, 'Explore'),
          _buildNavigationItem(2, Icons.add_box_rounded, 'Create Post'),
          _buildNavigationItem(3, Icons.chat_bubble_outline, 'Chat'),
          _buildNavigationItem(4, Icons.person_outline, 'Profile'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: widget.isDarkMode,
              onChanged: widget.onThemeChanged,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Main responsive layout
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= 1000) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 270,
                  child: _buildNavigationMenu(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        title: Text(
                          pageTitles[selectedIndex],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        actions: [
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notifications coming soon!',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.notifications_outlined),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      Expanded(child: _buildSelectedPage()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (width >= 600) {
          return Scaffold(
            appBar: AppBar(
              title: Text(pageTitles[selectedIndex]),
              actions: [
                IconButton(
                  tooltip: 'Toggle theme',
                  onPressed: () {
                    widget.onThemeChanged(!widget.isDarkMode);
                  },
                  icon: Icon(
                    widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                ),
              ],
            ),
            drawer: Drawer(child: _buildNavigationMenu()),
            body: _buildSelectedPage(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(pageTitles[selectedIndex]),
            actions: [
              IconButton(
                tooltip: 'Toggle theme',
                onPressed: () {
                  widget.onThemeChanged(!widget.isDarkMode);
                },
                icon: Icon(
                  widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
              ),
            ],
          ),
          body: _buildSelectedPage(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() => selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_box_outlined),
                selectedIcon: Icon(Icons.add_box),
                label: 'Create',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

// Reusable action button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: effectiveColor, size: 20),
      label: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
