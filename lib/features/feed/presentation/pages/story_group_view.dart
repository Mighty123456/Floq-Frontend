import 'package:flutter/material.dart';
import 'story_view_page.dart';

class StoryGroupView extends StatefulWidget {
  final List<Map<String, dynamic>> userStories;
  final int initialUserIndex;

  const StoryGroupView({
    super.key,
    required this.userStories,
    required this.initialUserIndex,
  });

  @override
  State<StoryGroupView> createState() => _StoryGroupViewState();
}

class _StoryGroupViewState extends State<StoryGroupView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialUserIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.userStories.length,
      itemBuilder: (context, index) {
        final user = widget.userStories[index];
        return StoryViewPage(
          userName: user["userName"],
          profileUrl: user["profileUrl"],
          stories: user["stories"],
          onAllStoriesComplete: () {
            if (index < widget.userStories.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
            } else {
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }
}
