import 'package:connecthub/features/chat_page.dart';
import 'package:connecthub/features/create_post_page.dart';
import 'package:connecthub/features/explore_page.dart';
import 'package:connecthub/features/post_search_bar.dart';
import 'package:connecthub/features/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connecthub/models/post_model.dart';
import 'package:connecthub/models/user_model.dart';
import 'package:connecthub/service/post_service.dart';
import 'package:connecthub/features/post_card.dart';

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

  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

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

  List<PostModel> get filteredPosts {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return apiPosts;

    return apiPosts.where((post) {
      return post.title.toLowerCase().contains(query) ||
          post.body.toLowerCase().contains(query);
    }).toList();
  }

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
    searchController.dispose();

    for (final controller in commentControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (searchQuery.trim().isEmpty) {
        loadMorePosts();
      }
    }
  }

  // Fetch image data and attach it to each post.
  Future<List<PostModel>> attachPhotos(
    List<PostModel> posts, {
    required int page,
  }) async {
    try {
      final photos = await PostService.fetchPhotos(
        page: page,
        limit: pageSize,
      );

      final photoById = <int, Map<String, dynamic>>{
        for (final photo in photos) photo['id'] as int: photo,
      };

      return posts.map((post) {
        final photo = photoById[post.id];

        return PostModel(
          userId: post.userId,
          id: post.id,
          title: post.title,
          body: post.body,
          imageUrl: photo?['url'] as String?,
          thumbnailUrl: photo?['thumbnailUrl'] as String?,
        );
      }).toList();
    } catch (_) {
      // Keep posts visible even if the photo API fails.
      return posts;
    }
  }

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
      final posts = await PostService.fetchPosts(page: 1, limit: pageSize);

      final postsWithPhotos = await attachPhotos(posts, page: 1);

      if (!mounted) return;

      setState(() {
        apiPosts = postsWithPhotos;
        currentPage = 1;
        hasMore = posts.length == pageSize;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Posts could not load. Check your internet.';
        isLoading = false;
      });
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoading || isLoadingMore || !hasMore || loadMoreError != null) {
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

      final newPostsWithPhotos = await attachPhotos(newPosts, page: nextPage);

      if (!mounted) return;

      setState(() {
        final existingIds = apiPosts.map((post) => post.id).toSet();

        final uniquePosts = newPostsWithPhotos
            .where((post) => !existingIds.contains(post.id))
            .toList();

        apiPosts.addAll(uniquePosts);

        currentPage = nextPage;
        hasMore = newPosts.length == pageSize;
        isLoadingMore = false;
        loadMoreError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingMore = false;
        loadMoreError = 'Could not load more posts.';
      });
    }
  }

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

  void toggleLike(PostModel post) {
    setState(() {
      if (likedPostIds.contains(post.id)) {
        likedPostIds.remove(post.id);
        likeCounts[post.id] = ((likeCounts[post.id] ?? 1) - 1).clamp(0, 999999);
      } else {
        likedPostIds.add(post.id);
        likeCounts[post.id] = (likeCounts[post.id] ?? 0) + 1;
      }
    });
  }

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

  Widget _buildPostCard(PostModel post) {
    return PostCard(
      post: post,
      localImageBytes: post.localImageBytes,
      isLiked: likedPostIds.contains(post.id),
      likeCount: likeCounts[post.id] ?? 0,
      comments: postComments[post.id] ?? [],
      commentController: commentControllers.putIfAbsent(
        post.id,
        () => TextEditingController(),
      ),
      getUser: getUser,
      onLike: () => toggleLike(post),
      onAddComment: () => addComment(post),
    );
  }

  // ------------------------------------------------------------
  // Loading skeleton (pulsing)
  // ------------------------------------------------------------

  Widget _buildLoadingState() {
    final colors = Theme.of(context).colorScheme;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _Pulse(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _skeletonBox(46, 46, radius: 50),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _skeletonBox(150, 12),
                              const SizedBox(height: 8),
                              _skeletonBox(90, 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _skeletonBox(double.infinity, 220, radius: 16),
                    const SizedBox(height: 16),
                    _skeletonBox(220, 13),
                    const SizedBox(height: 9),
                    _skeletonBox(170, 13),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _skeletonBox(65, 28, radius: 10),
                        const SizedBox(width: 16),
                        _skeletonBox(75, 28, radius: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _skeletonBox(double width, double height, {double radius = 6}) {
    return Container(
      width: width.isInfinite ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: PostSearchBar(
            controller: searchController,
            onChanged: (value) {
              setState(() => searchQuery = value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final colors = Theme.of(context).colorScheme;

    if (isLoading) {
      return Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadPosts,
              child: _buildLoadingState(),
            ),
          ),
        ],
      );
    }

    if (errorMessage != null) {
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
                  Icons.cloud_off_rounded,
                  size: 42,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 18),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: loadPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSearchHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadPosts,
            child: Builder(
              builder: (context) {
                final posts = filteredPosts;
                final searching = searchQuery.trim().isNotEmpty;

                if (posts.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 70),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            searching
                                ? Icons.search_off_rounded
                                : Icons.dynamic_feed_outlined,
                            size: 42,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          searching
                              ? 'No matching posts found.'
                              : 'No posts found.',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                }

                final showFooter = !searching &&
                    (isLoadingMore || loadMoreError != null || !hasMore);

                return ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  itemCount: posts.length + (showFooter ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == posts.length) {
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
                                FilledButton.tonal(
                                  onPressed: () {
                                    setState(() {
                                      loadMoreError = null;
                                    });
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text('🎉 You have seen all posts!'),
                            ),
                          ),
                        );
                      }
                    }

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildPostCard(posts[index]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const ExplorePage();
      case 2:
        return CreatePostPage(
          onPostCreated: (post) {
            setState(() {
              apiPosts.insert(0, post);
              selectedIndex = 0;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('new post  is added to Home feed!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      case 3:
        return const ChatPage();
      default:
        return const ProfilePage();
    }
  }

  // ------------------------------------------------------------
  // Navigation (sidebar / drawer)
  // ------------------------------------------------------------

  Widget _buildNavigationItem(int index, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    final selected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        leading: Icon(icon, color: selected ? colors.primary : null),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? colors.primary : null,
          ),
        ),
        selected: selected,
        selectedTileColor: colors.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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

  Widget _buildNavigationMenu() {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName ?? '').trim().isNotEmpty
        ? user!.displayName!.trim()
        : 'ConnectHub User';

    return SafeArea(
      child: Column(
        children: [
          // Brand
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 22, 18, 10),
            child: Row(
              children: [
                Icon(Icons.hub_rounded, color: Color(0xFF2684FF), size: 34),
                SizedBox(width: 10),
                Text(
                  'ConnectHub',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // User chip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.primary,
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (user?.email != null)
                          Text(
                            user!.email!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onChanged: widget.onThemeChanged,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // App bar
  // ------------------------------------------------------------

  PreferredSizeWidget _buildAppBar({required bool showThemeToggle}) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      titleSpacing: 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedIndex == 0) ...[
            Icon(Icons.hub_rounded, color: colors.primary, size: 28),
            const SizedBox(width: 8),
          ],
          Text(
            selectedIndex == 0 ? 'ConnectHub' : pageTitles[selectedIndex],
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon!')),
            );
          },
          icon: const Icon(Icons.notifications_outlined),
        ),
        if (showThemeToggle)
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= 1000) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 270, child: _buildNavigationMenu()),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      _buildAppBar(showThemeToggle: false),
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
            appBar: _buildAppBar(showThemeToggle: true),
            drawer: Drawer(child: _buildNavigationMenu()),
            body: _buildSelectedPage(),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(showThemeToggle: true),
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

// Gently pulsing opacity used for skeleton loading cards.
class _Pulse extends StatefulWidget {
  final Widget child;

  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.45, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}