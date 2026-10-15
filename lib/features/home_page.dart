import 'package:connecthub/service/post_service.dart';
import 'package:flutter/material.dart';
import '../../widgets/post_card.dart';

class HomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

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
  final TextEditingController postController = TextEditingController();

  List<dynamic> apiPosts = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadPosts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await PostService.fetchPosts();

      if (!mounted) return;

      setState(() {
        apiPosts = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Posts load korte problem hoyeche.';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  final List<Map<String, dynamic>> posts = [
    {
      'name': 'Rahim Ahmed',
      'username': '@rahim',
      'message': 'Hello everyone! Welcome to my community.',
      'color': Colors.blue,
    },
    {
      'name': 'Nusrat Jahan',
      'username': '@nusrat',
      'message': 'Today is a beautiful day! 😊',
      'color': Colors.pink,
    },
    {
      'name': 'Sakib Hasan',
      'username': '@sakib',
      'message': 'Learning Flutter and building something new!',
      'color': Colors.green,
    },
  ];

  void publishPost() {
    final message = postController.text.trim();

    if (message.isEmpty) return;

    setState(() {
      posts.insert(0, {
        'name': 'You',
        'username': '@you',
        'message': message,
        'color': Colors.deepPurple,
      });

      postController.clear();
      selectedIndex = 0;
    });

    FocusScope.of(context).unfocus();
  }

  final List<String> pageTitles = [
    'Home',
    'Explore',
    'Create Post',
    'Chat',
    'Profile',
  ];

  Widget _buildHomeContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage!),
              const SizedBox(height: 12),
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

    return RefreshIndicator(
      onRefresh: loadPosts,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: apiPosts.length,
        itemBuilder: (context, index) {
          final post = apiPosts[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User ID: ${post['userId']}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['title']?.toString() ?? 'Untitled',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(post['body']?.toString() ?? ''),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedPage() {
    if (selectedIndex == 0) {
      return _buildHomeContent();
    }

    if (selectedIndex == 1) {
      return const Center(
        child: Text('Explore Page 🔎', style: TextStyle(fontSize: 24)),
      );
    }
    if (selectedIndex == 2) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create a Post ✍️',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: postController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'What is on your mind?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: publishPost,
              icon: const Icon(Icons.send),
              label: const Text('Publish Post'),
            ),
          ],
        ),
      );
    }

    if (selectedIndex == 3) {
      return const Center(
        child: Text('Chat Page 💬', style: TextStyle(fontSize: 24)),
      );
    }

    return const Center(
      child: Text('Your Profile 👤', style: TextStyle(fontSize: 24)),
    );
  }

  Widget _buildNavigationItem(int index) {
    final icons = [
      Icons.home_outlined,
      Icons.explore_outlined,
      Icons.add_circle_outline,
      Icons.chat_bubble_outline,
      Icons.person_outline,
    ];

    final selectedIcons = [
      Icons.home,
      Icons.explore,
      Icons.add_circle,
      Icons.chat_bubble,
      Icons.person,
    ];

    return ListTile(
      leading: Icon(
        selectedIndex == index ? selectedIcons[index] : icons[index],
      ),
      title: Text(pageTitles[index]),
      selected: selectedIndex == index,
      onTap: () {
        setState(() {
          selectedIndex = index;
        });

        if (MediaQuery.of(context).size.width >= 600) {
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('ConnectHub · ${pageTitles[selectedIndex]}'),
        actions: [
          IconButton(
            onPressed: widget.onThemeChanged,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Change theme',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),

      drawer: !isMobile
          ? Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'ConnectHub',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    for (int i = 0; i < pageTitles.length; i++)
                      _buildNavigationItem(i),
                  ],
                ),
              ),
            )
          : null,

      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 240,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'ConnectHub',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(),
                      for (int i = 0; i < pageTitles.length; i++)
                        _buildNavigationItem(i),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: _buildSelectedPage(),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  label: 'Explore',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_circle_outline),
                  label: 'Create',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: 'Chat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }
}
