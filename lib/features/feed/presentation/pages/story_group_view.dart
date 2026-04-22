import 'package:flutter/material.dart';
import '../../domain/entities/story_entity.dart';
import 'story_view_page.dart';

class StoryGroupView extends StatefulWidget {
  final List<StoryGroupEntity> storyGroups;
  final int initialGroupIndex;

  const StoryGroupView({
    super.key,
    required this.storyGroups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryGroupView> createState() => _StoryGroupViewState();
}

class _StoryGroupViewState extends State<StoryGroupView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialGroupIndex);
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
      itemCount: widget.storyGroups.length,
      itemBuilder: (context, index) {
        final group = widget.storyGroups[index];
        return StoryViewPage(
          userName: group.userName,
          profileUrl: group.userAvatar,
          stories: group.stories,
          onAllStoriesComplete: () {
            if (index < widget.storyGroups.length - 1) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
            } else {
              Navigator.pop(context);
            }
          },
          onClose: () => Navigator.pop(context),
        );
      },
    );
  }
}

