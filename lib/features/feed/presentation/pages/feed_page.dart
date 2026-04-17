import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'story_view_page.dart';
import 'story_group_view.dart';
import '../../../users/presentation/pages/users_page.dart';


class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  void _showZoomedImage(BuildContext context, String imageUrl, String heroTag) {
    if (imageUrl.isEmpty) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Hero(
                  tag: heroTag,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  final List<Map<String, dynamic>> _mockPosts = [
    {
      "id": "1",
      "userName": "Christopher Columbus",
      "profileUrl": "https://i.pravatar.cc/150?u=a042581f4e29026704d",
      "timeAgo": "2h",
      "content": "Just launched a new feature on the Floq platform! So excited to share this with everyone. Let me know your thoughts in the comments! 🚀💻",
      "imageUrl": "https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=600&q=80",
      "likes": 124,
      "comments": 18,
      "isLiked": false,
      "isSaved": false,
    },
    {
      "id": "2",
      "userName": "Emma Watson",
      "profileUrl": "https://i.pravatar.cc/150?u=a042581f4e29026024d",
      "timeAgo": "5h",
      "content": "Exploring the beautiful landscapes and finding peace in nature today. Sometimes you just need to disconnect to reconnect. 🌲✨",
      "imageUrl": "https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=600&q=80",
      "likes": 532,
      "comments": 45,
      "isLiked": true,
      "isSaved": true,
    },
    {
      "id": "3",
      "userName": "David Chen",
      "profileUrl": "https://i.pravatar.cc/150?u=a04258114e29026702d",
      "timeAgo": "1d",
      "content": "Clean Architecture in Flutter is an absolute game changer. Finally untangled my entire state management mess! Highly recommend organizing your code by features rather than layers. 🏗️🔥",
      "imageUrl": "",
      "likes": 89,
      "comments": 12,
      "isLiked": false,
      "isSaved": false,
    },
  ];

  void _showCommentsSheet(BuildContext context, Map<String, dynamic> post, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Map<String, String>> mockComments = [
      {"user": "Alice", "comment": "This looks incredible! 🤩"},
      {"user": "Bob", "comment": "Great share, thanks for the info."},
      {"user": "Charlie", "comment": "Awesome! Can't wait to see more."},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Comments",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mockComments.length,
                itemBuilder: (context, index) {
                  final comment = mockComments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=${comment['user']}"),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment['user']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                comment['comment']!,
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text("2h ago • Reply", style: TextStyle(color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                        const Icon(Icons.favorite_border_rounded, size: 14, color: Colors.grey),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
              ),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, backgroundImage: NetworkImage(post['profileUrl'])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Post", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Stories Section
          SliverToBoxAdapter(
            child: _buildStorySection(isDark, colorScheme),
          ),



          // Main Feed Posts
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = _mockPosts[index];
                
                // Insert suggested connections after the first post
                if (index == 1) {
                  return Column(
                    children: [
                      _buildSuggestedNetwork(isDark, colorScheme),
                      _buildUniquePostCard(post, isDark, colorScheme),
                    ],
                  );
                }
                
                return _buildUniquePostCard(post, isDark, colorScheme);
              },
              childCount: _mockPosts.length,
            ),
          ),
          
          // Bottom spacing for Navbar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _mockStoryUsers = List.generate(10, (index) => {
    "userName": index == 0 ? "Your Story" : "User $index",
    "profileUrl": "https://i.pravatar.cc/150?u=story_$index",
    "stories": [
      StoryItem(url: "https://picsum.photos/seed/story_${index}_1/800/1200"),
      StoryItem(url: "https://picsum.photos/seed/story_${index}_2/800/1200"),
    ],
  });

  void _openStories(BuildContext context, int userIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryGroupView(
          userStories: _mockStoryUsers,
          initialUserIndex: userIndex,
        ),
      ),
    );
  }

  Widget _buildStorySection(bool isDark, ColorScheme colorScheme) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _mockStoryUsers.length,
        itemBuilder: (context, index) {
          final user = _mockStoryUsers[index];
          
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => _openStories(context, 0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(user["profileUrl"]),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(user["userName"], style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _openStories(context, index),
              child: Column(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary, Colors.orangeAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(user["profileUrl"]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user["userName"], style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestedNetwork(bool isDark, ColorScheme colorScheme) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Discover new people",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UsersPage()),
                  );
                },
                child: Text(
                  "See all",
                  style: GoogleFonts.poppins(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12, bottom: 20, top: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage("https://i.pravatar.cc/150?u=suggested_$index"),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      index % 2 == 0 ? "Dr. Strange" : "Wanda Maximoff",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      "Suggested for you",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Follow",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUniquePostCard(Map<String, dynamic> post, bool isDark, ColorScheme colorScheme) {
    final hasImage = post['imageUrl'].isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(post['profileUrl']),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['userName'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    post['timeAgo'],
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onPressed: () {},
              )
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Main Content Layer
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Content Background (Text or Image)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Column(
                    children: [
                      if (hasImage)
                        GestureDetector(
                          onTap: () => _showZoomedImage(context, post['imageUrl'], 'feed_image_${post['id']}'),
                          child: Hero(
                            tag: 'feed_image_${post['id']}',
                            child: Image.network(
                              post['imageUrl'],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              height: 350,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, hasImage ? 20 : 24, 65, 24),
                        child: Text(
                          post['content'],
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.6,
                            letterSpacing: 0.2,
                            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Vertical Action Bar (Piercing the side)
              Positioned(
                right: 12,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildActionIcon(
                        icon: post['isLiked'] ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: post['isLiked'] ? Colors.redAccent : null,
                        count: post['likes'].toString(),
                        onTap: () {
                          setState(() {
                            post['isLiked'] = !post['isLiked'];
                            post['likes'] += post['isLiked'] ? 1 : -1;
                          });
                        },
                      ),
                      const Divider(height: 10, indent: 4, endIndent: 4),
                      _buildActionIcon(
                        icon: Icons.chat_bubble_outline_rounded,
                        count: post['comments'].toString(),
                        onTap: () => _showCommentsSheet(context, post, isDark),
                      ),
                      const Divider(height: 10, indent: 4, endIndent: 4),
                      _buildActionIcon(
                        icon: post['isSaved'] ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        onTap: () {
                          setState(() {
                            post['isSaved'] = !post['isSaved'];
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({required IconData icon, Color? color, String? count, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            if (count != null)
              Text(
                count,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
