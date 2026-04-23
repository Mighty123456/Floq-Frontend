import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import '../../../../core/presentation/widgets/floq_avatar.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import 'story_camera_flow.dart';
import 'package:geolocator/geolocator.dart';

enum PostType { post, story, reel, live }

class PostCreationFlow extends StatefulWidget {
  const PostCreationFlow({super.key});

  @override
  State<PostCreationFlow> createState() => _PostCreationFlowState();
}

class _PostCreationFlowState extends State<PostCreationFlow> {
  int _currentStep = 0;
  PostType _selectedType = PostType.post;
  List<AssetEntity> _selectedAssets = [];
  AssetEntity? _primaryAsset;
  int _selectedFilterIndex = 0;
  String _overlayText = "";
  Map<String, String>? _selectedAudio;
  
  // Post Details
  final TextEditingController _captionController = TextEditingController();
  String? _locationName;
  Position? _currentPosition;
  String? _audioName;
  String? _audioUrl;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return GalleryPickerStep(
          onNext: (assets, type) {
            setState(() {
              _selectedAssets = assets;
              _primaryAsset = assets.first;
              _selectedType = type;
              _currentStep = 1;
            });
          },
          onClose: () => Navigator.pop(context),
        );
      case 1:
        return MediaPreviewStep(
          asset: _primaryAsset!,
          onNext: (filterIdx, text, audio) => setState(() {
            _selectedFilterIndex = filterIdx;
            _overlayText = text;
            _selectedAudio = audio;
            _currentStep = 2;
          }),
          onBack: () => setState(() => _currentStep = 0),
        );
      case 2:
        return PostDetailsStep(
          primaryAsset: _primaryAsset!,
          captionController: _captionController,
          selectedType: _selectedType,
          onShare: _handleShare,
          onBack: () => setState(() => _currentStep = 1),
          selectedFilterIndex: _selectedFilterIndex,
          overlayText: _overlayText,
          selectedAudio: _selectedAudio,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleShare() async {
    if (_selectedAssets.isEmpty) return;

    final mediaFiles = <File>[];
    for (var asset in _selectedAssets) {
      final file = await asset.file;
      if (file != null) mediaFiles.add(file);
    }

    if (mounted) {
       final metadata = {
         'isPremium': false,
         'allowComments': true,
       };

       context.read<FeedBloc>().add(CreatePostRequested(
         _captionController.text,
         mediaFiles.map((f) => f.path).toList(),
         type: _selectedType.name,
         location: _locationName != null ? {
           'name': _locationName,
           'lat': _currentPosition?.latitude,
           'lng': _currentPosition?.longitude,
         } : null,
         audioData: _audioUrl != null ? {
           'url': _audioUrl,
           'name': _audioName,
         } : null,
         metadata: metadata,
       ));
       
       Navigator.pop(context);
       BubbleNotification.show(context, "Your ${_selectedType.name} is being shared!");
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1: GALLERY PICKER
// ─────────────────────────────────────────────────────────────────────────────
class GalleryPickerStep extends StatefulWidget {
  final Function(List<AssetEntity>, PostType) onNext;
  final VoidCallback onClose;

  const GalleryPickerStep({super.key, required this.onNext, required this.onClose});

  @override
  State<GalleryPickerStep> createState() => _GalleryPickerStepState();
}

class _GalleryPickerStepState extends State<GalleryPickerStep> {
  List<AssetEntity> _assets = [];
  List<AssetEntity> _selected = [];
  AssetEntity? _previewAsset;
  PostType _type = PostType.post;
  bool _multiSelect = false;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        // Fetch all albums to find any media
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.common,
        );
        
        List<AssetEntity> allAssets = [];
        for (var album in albums) {
          final count = await album.assetCountAsync;
          if (count > 0) {
            final assets = await album.getAssetListRange(start: 0, end: 100);
            allAssets.addAll(assets);
          }
        }

        // Sort by date (descending) if needed, but usually photo_manager does this
        if (mounted) {
          setState(() {
            _assets = allAssets;
            if (_assets.isNotEmpty) {
              _previewAsset = _assets.first;
            } else {
              _previewAsset = null;
            }
          });
        }
      } else {
        if (mounted) {
           BubbleNotification.show(context, "Gallery permission is required to post", type: NotificationType.error);
           // Delay slightly to let the notification be seen before jumping to settings
           Future.delayed(const Duration(seconds: 1), () => PhotoManager.openSetting());
        }
      }
    } catch (e) {
      debugPrint("Error fetching assets: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildPreview(),
          _buildMediaGrid(),
          _buildTypeSelector(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, color: Colors.white)),
          Row(
            children: [
              Text("New post", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                onPressed: _fetchAssets,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              if (_selected.isEmpty && _previewAsset != null) _selected = [_previewAsset!];
              if (_selected.isNotEmpty) widget.onNext(_selected, _type);
            },
            child: Text("Next", style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Expanded(
      flex: 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            width: double.infinity,
            color: Colors.black,
            child: _previewAsset == null 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      Text("No Photos Found", style: GoogleFonts.poppins(color: Colors.white24)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAssets,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                        child: Text("Grant Permission", style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              : FloqGalleryImage(asset: _previewAsset!),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.unfold_more, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    return Expanded(
      flex: 4,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Recents", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _multiSelect = !_multiSelect),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _multiSelect ? Colors.blueAccent : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.copy, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text("Select", style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 1, mainAxisSpacing: 1),
              itemCount: _assets.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryCameraFlow()));
                    },
                    child: Container(
                      color: Colors.white12,
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                    ),
                  );
                }
                final asset = _assets[index - 1];
                final isSelected = _selected.contains(asset);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _previewAsset = asset;
                      if (_multiSelect) {
                        if (isSelected) {
                          _selected.remove(asset);
                        } else {
                          _selected.add(asset);
                        }
                      } else {
                        _selected = [asset];
                      }
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FloqGalleryImage(asset: asset),
                      if (isSelected) Container(color: Colors.white24),
                      if (_multiSelect) Positioned(
                        top: 4, right: 4,
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            color: isSelected ? Colors.blueAccent : Colors.black26,
                          ),
                          child: isSelected ? const Center(child: Text("1", style: TextStyle(color: Colors.white, fontSize: 10))) : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      height: 60,
      color: Colors.black,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: PostType.values.map((t) {
          final isSelected = _type == t;
          return GestureDetector(
            onTap: () => setState(() => _type = t),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                t.name.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2: MEDIA PREVIEW & EDIT
// ─────────────────────────────────────────────────────────────────────────────
class MediaPreviewStep extends StatefulWidget {
  final AssetEntity asset;
  final Function(int, String, Map<String, String>?) onNext;
  final VoidCallback onBack;

  const MediaPreviewStep({super.key, required this.asset, required this.onNext, required this.onBack});

  @override
  State<MediaPreviewStep> createState() => _MediaPreviewStepState();
}

class _MediaPreviewStepState extends State<MediaPreviewStep> {
  int _selectedFilterIndex = 0;
  String _overlayText = "";
  Map<String, String>? _selectedAudio;
  final TextEditingController _textEditorController = TextEditingController();

  final List<ColorFilter> _filters = [
    const ColorFilter.mode(Colors.transparent, BlendMode.dst),
    const ColorFilter.matrix([
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ]), // Sepia
    const ColorFilter.matrix([
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ]), // Grayscale
    ColorFilter.mode(Colors.blue.withValues(alpha: 0.2), BlendMode.colorBurn),
    ColorFilter.mode(Colors.pink.withValues(alpha: 0.2), BlendMode.softLight),
    ColorFilter.mode(Colors.yellow.withValues(alpha: 0.2), BlendMode.overlay),
  ];

  final List<String> _filterNames = ["Normal", "Sepia", "Mono", "Ocean", "Candy", "Sun"];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: ColorFiltered(
                    colorFilter: _filters[_selectedFilterIndex],
                    child: FloqGalleryImage(asset: widget.asset, fit: BoxFit.contain),
                  ),
                ),
                if (_overlayText.isNotEmpty)
                  Positioned(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _overlayText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_selectedAudio != null)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_note, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${_selectedAudio!['title']} • ${_selectedAudio!['artist']}",
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildEditToolbar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: widget.onBack, icon: const Icon(Icons.close, color: Colors.white)),
          const Spacer(),
          IconButton(onPressed: () => _showEditorSheet(context, "Audio"), icon: const Icon(Icons.music_note, color: Colors.white)),
          IconButton(onPressed: () => _showEditorSheet(context, "Text"), icon: const Icon(Icons.text_fields, color: Colors.white)),
          IconButton(onPressed: () => _showEditorSheet(context, "Effects"), icon: const Icon(Icons.auto_awesome, color: Colors.white)),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => widget.onNext(_selectedFilterIndex, _overlayText, _selectedAudio),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: const StadiumBorder()),
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  Widget _buildEditToolbar(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _toolItem(context, Icons.music_note, "Audio"),
          _toolItem(context, Icons.text_fields, "Text"),
          _toolItem(context, Icons.layers, "Overlay"),
          _toolItem(context, Icons.filter, "Filter"),
          _toolItem(context, Icons.tune, "Edit"),
        ],
      ),
    );
  }

  Widget _toolItem(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () => _showEditorSheet(context, label),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  void _showEditorSheet(BuildContext context, String tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: tool == "Text",
      builder: (context) => Container(
        height: tool == "Text" ? MediaQuery.of(context).size.height * 0.8 : 300,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tool, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    onPressed: () {
                      if (tool == "Text") {
                        setState(() => _overlayText = _textEditorController.text);
                      }
                      Navigator.pop(context);
                    }, 
                    icon: const Icon(Icons.check, color: Colors.blueAccent)
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: _buildToolContent(tool),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolContent(String tool) {
    if (tool == "Filter") {
      return StatefulBuilder(
        builder: (context, setSheetState) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _filters.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              setSheetState(() => _selectedFilterIndex = index);
              setState(() => _selectedFilterIndex = index);
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedFilterIndex == index ? Colors.blueAccent : Colors.transparent, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.filter_hdr, color: Colors.white38),
                  const SizedBox(height: 8),
                  Text(_filterNames[index], style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    if (tool == "Audio") {
      return StatefulBuilder(
        builder: (context, setSheetState) => ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            final title = "Trending Track $index";
            final artist = "Popular Artist";
            final isSelected = _selectedAudio?['title'] == title;
            
            return ListTile(
              onTap: () {
                setSheetState(() {
                   if (isSelected) {
                     _selectedAudio = null;
                   } else {
                     _selectedAudio = {"title": title, "artist": artist};
                   }
                });
                setState(() {}); // Update main preview
              },
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent : Colors.white10, 
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Icon(isSelected ? Icons.music_note : Icons.music_video, color: Colors.white70),
              ),
              title: Text(title, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white, fontSize: 14)),
              subtitle: Text(artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, color: isSelected ? Colors.blueAccent : Colors.white38),
            );
          },
        ),
      );
    }

    if (tool == "Text") {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: TextField(
          controller: _textEditorController,
          autofocus: true,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: "Type something...",
            hintStyle: TextStyle(color: Colors.white24),
            border: InputBorder.none,
          ),
          onChanged: (val) {
             // Real-time preview if desired
          },
        ),
      );
    }

    return Center(
      child: Text("$tool settings coming soon!", style: const TextStyle(color: Colors.white54)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3: POST DETAILS
// ─────────────────────────────────────────────────────────────────────────────
class PostDetailsStep extends StatefulWidget {
  final AssetEntity primaryAsset;
  final TextEditingController captionController;
  final PostType selectedType;
  final VoidCallback onShare;
  final VoidCallback onBack;
  final int selectedFilterIndex;
  final String overlayText;
  final Map<String, String>? selectedAudio;

  const PostDetailsStep({
    super.key, 
    required this.primaryAsset, 
    required this.captionController,
    required this.selectedType,
    required this.onShare,
    required this.onBack,
    this.selectedFilterIndex = 0,
    this.overlayText = "",
    this.selectedAudio,
  });

  @override
  State<PostDetailsStep> createState() => _PostDetailsStepState();
}

class _DetailsFilters {
  static final List<ColorFilter> filters = [
    const ColorFilter.mode(Colors.transparent, BlendMode.dst),
    const ColorFilter.matrix([
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ]), // Sepia
    const ColorFilter.matrix([
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ]), // Grayscale
    ColorFilter.mode(Colors.blue.withValues(alpha: 0.2), BlendMode.colorBurn),
    ColorFilter.mode(Colors.pink.withValues(alpha: 0.2), BlendMode.softLight),
    ColorFilter.mode(Colors.yellow.withValues(alpha: 0.2), BlendMode.overlay),
  ];
}

class _PostDetailsStepState extends State<PostDetailsStep> {
  String _myAvatar = "";
  String _myName = "Me";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final storage = SecureStorageService();
    final userJson = await storage.getUser();
    if (userJson != null) {
      final map = jsonDecode(userJson);
      setState(() {
        _myAvatar = map['avatar']?['url'] ?? "";
        _myName = map['name'] ?? "Me";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text("New ${widget.selectedType.name}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        leading: IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
        actions: [
          TextButton(onPressed: widget.onShare, child: const Text("Share", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Preview Card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FloqAvatar(radius: 18, name: _myName, imageUrl: _myAvatar),
                      const SizedBox(width: 10),
                      Text(_myName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      const Icon(Icons.more_vert_rounded, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              ColorFiltered(
                                colorFilter: _DetailsFilters.filters[widget.selectedFilterIndex],
                                child: FloqGalleryImage(asset: widget.primaryAsset, fit: BoxFit.cover),
                              ),
                              if (widget.overlayText.isNotEmpty)
                                Positioned(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                      widget.overlayText,
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                                    ),
                                  ),
                                ),
                              if (widget.selectedAudio != null)
                                Positioned(
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.music_note, color: Colors.white, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${widget.selectedAudio!['title']} • ${widget.selectedAudio!['artist']}",
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: widget.captionController,
                              maxLines: 3,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: "Write a caption...",
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            _listTile(Icons.location_on_outlined, "Add location"),
            _listTile(Icons.person_add_alt, "Tag people"),
            _listTile(
              Icons.music_note, 
              widget.selectedAudio != null ? "${widget.selectedAudio!['title']}" : "Add music",
              subtitle: widget.selectedAudio != null ? widget.selectedAudio!['artist'] : null
            ),
            const Divider(),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: widget.onShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Share Post", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listTile(IconData icon, String title, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {},
    );
  }
}

class FloqGalleryImage extends StatelessWidget {
  final AssetEntity asset;
  final BoxFit fit;
  const FloqGalleryImage({super.key, required this.asset, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: asset.thumbnailData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: fit);
        }
        return Container(color: Colors.white10);
      },
    );
  }
}
