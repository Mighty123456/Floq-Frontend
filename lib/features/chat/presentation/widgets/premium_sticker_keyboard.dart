import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/presentation/widgets/bouncy_button.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/services/giphy_service.dart';

class PremiumStickerKeyboard extends StatefulWidget {
  final Function(String) onStickerSelected;
  final Function(String) onGifSelected;
  final VoidCallback onCreateSticker;

  const PremiumStickerKeyboard({
    super.key,
    required this.onStickerSelected,
    required this.onGifSelected,
    required this.onCreateSticker,
  });

  @override
  State<PremiumStickerKeyboard> createState() => _PremiumStickerKeyboardState();
}

class _PremiumStickerKeyboardState extends State<PremiumStickerKeyboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final GiphyService _giphyService = GiphyService();

  List<String> _stickers = [];
  List<String> _gifs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadContent();
      }
    });
    _loadContent();
    
    _searchController.addListener(() {
      _onSearchChanged();
    });
  }

  void _loadContent() async {
    setState(() => _isLoading = true);
    if (_tabController.index == 0) {
      final stickers = await _giphyService.getTrendingStickers();
      if (mounted) setState(() { _stickers = stickers; _isLoading = false; });
    } else {
      final gifs = await _giphyService.getTrendingGifs();
      if (mounted) setState(() { _gifs = gifs; _isLoading = false; });
    }
  }

  void _onSearchChanged() async {
    final query = _searchController.text;
    if (query.length < 2 && query.isNotEmpty) return;
    
    // Simple debounce would be better, but for now:
    if (_tabController.index == 0) {
      final stickers = await _giphyService.searchStickers(query);
      if (mounted) setState(() => _stickers = stickers);
    } else {
      final gifs = await _giphyService.searchGifs(query);
      if (mounted) setState(() => _gifs = gifs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 330,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Column(
        children: [
          // Header / Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Search GIPHY stickers & GIFs...",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                BouncyButton(
                  onTap: widget.onCreateSticker,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_fix_high_rounded, color: colorScheme.primary, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Categories Row
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildCategoryPill("Trending", Icons.trending_up),
                _buildCategoryPill("Love", Icons.favorite_rounded),
                _buildCategoryPill("Funny", Icons.sentiment_very_satisfied_rounded),
                _buildCategoryPill("React", Icons.bolt_rounded),
                _buildCategoryPill("Sad", Icons.sentiment_very_dissatisfied_rounded),
                _buildCategoryPill("Ok", Icons.thumb_up_rounded),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelColor: isDark ? Colors.white : Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "Stickers"),
              Tab(text: "GIFs"),
            ],
          ),

          // Content
          Expanded(
            child: _isLoading 
              ? const Center(child: BubbleLoader())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGrid(_stickers, true, isDark),
                    _buildGrid(_gifs, false, isDark),
                  ],
                ),
          ),
          
          // Giphy Branding
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text("Powered by GIPHY", style: TextStyle(fontSize: 8, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<String> items, bool isSticker, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSticker ? 4 : 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isSticker ? 1.0 : 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return BouncyButton(
          onTap: () => isSticker ? widget.onStickerSelected(items[index]) : widget.onGifSelected(items[index]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: items[index],
              fit: isSticker ? BoxFit.contain : BoxFit.cover,
              placeholder: (context, url) => Container(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPill(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _searchController.text.toLowerCase() == label.toLowerCase() || 
                       (label == "Trending" && _searchController.text.isEmpty);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: BouncyButton(
        onTap: () {
          if (label == "Trending") {
            _searchController.clear();
            _loadContent();
          } else {
            _searchController.text = label;
            _onSearchChanged();
          }
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? colorScheme.primary 
                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? colorScheme.primary : (isDark ? Colors.white10 : Colors.black12),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
