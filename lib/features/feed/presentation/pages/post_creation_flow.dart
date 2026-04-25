import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
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
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:video_player/video_player.dart';
import '../../data/repositories/feed_repository_impl.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:http/http.dart' as http;
import '../../../../features/users/domain/repositories/users_repository.dart';
import '../../../../features/users/domain/entities/user_entity.dart';
import 'package:geocoding/geocoding.dart' as geo;






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
  Map<String, dynamic>? _selectedAudio;

  Map<String, dynamic>? _adjustments;
  
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
          assets: _selectedAssets,
          onNext: (filterIdx, text, audio, adjustments) => setState(() {
            _selectedFilterIndex = filterIdx;
            _overlayText = text;
            _selectedAudio = audio;
            _adjustments = adjustments;
            if (audio != null) {
              _audioName = audio['title'];
              _audioUrl = audio['url'];
            }
            _currentStep = 2;
          }),
          onBack: () => setState(() => _currentStep = 0),
        );
      case 2:
        return PostDetailsStep(
          assets: _selectedAssets,
          captionController: _captionController,
          selectedType: _selectedType,
          onShare: _handleShare,
          onBack: () => setState(() => _currentStep = 1),
          selectedFilterIndex: _selectedFilterIndex,
           overlayText: _overlayText,
           selectedAudio: _selectedAudio,
           adjustments: _adjustments,
           croppedFiles: _adjustments?['croppedFiles'] ?? {},
         );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleShare() async {
    if (_selectedAssets.isEmpty) return;

    final mediaFiles = <File>[];
    final croppedFiles = _adjustments?['croppedFiles'] as Map<String, File>? ?? {};
    
    for (var asset in _selectedAssets) {
      if (croppedFiles.containsKey(asset.id)) {
        mediaFiles.add(croppedFiles[asset.id]!);
      } else {
        final file = await asset.file;
        if (file != null) mediaFiles.add(file);
      }
    }


    if (mounted) {
       final metadata = {
         'isPremium': false,
         'allowComments': true,
       };

       // Show Premium Sharing Animation
       showGeneralDialog(
         context: context,
         barrierDismissible: false,
         barrierColor: Colors.black.withValues(alpha: 0.8),
         transitionDuration: const Duration(milliseconds: 500),
         pageBuilder: (context, anim1, anim2) => PostSharingOverlay(
           asset: _primaryAsset!,
           type: _selectedType.name,
         ),
       );

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
           'duration': _adjustments?['musicDuration'],
         } : null,
         metadata: metadata,
       ));
       
       // Delay pop to let animation breathe
       Future.delayed(const Duration(milliseconds: 3500), () {
         if (mounted) {
           Navigator.of(context).popUntil((route) => route.isFirst);
           BubbleNotification.show(context, "Your ${_selectedType.name} shared successfully!");
         }
       });
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
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
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
      final requestOption = PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      );

      PermissionState ps = await PhotoManager.getPermissionState(requestOption: requestOption);
      if (ps == PermissionState.notDetermined) {
        ps = await PhotoManager.requestPermissionExtend(requestOption: requestOption);
      }

      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        // Fetch All/Recent first for speed
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.common,
          onlyAll: true,
        );
        
        if (albums.isNotEmpty) {
          final selected = _selectedAlbum ?? albums.first;
          // Use pagination: only load the first 80 assets initially
          final assets = await selected.getAssetListPaged(page: 0, size: 80);

          if (mounted) {
            setState(() {
              _albums = albums;
              _selectedAlbum = selected;
              _assets = assets;
              if (_assets.isNotEmpty && _previewAsset == null) {
                _previewAsset = _assets.first;
              }
            });
          }

          // Fetch other albums in background
          PhotoManager.getAssetPathList(type: RequestType.common).then((all) {
            if (mounted) setState(() => _albums = all);
          });
        }
      } else {
        if (mounted) {
           BubbleNotification.show(context, "Gallery permission is required to post", type: NotificationType.error);
           Future.delayed(const Duration(seconds: 2), () => PhotoManager.openSetting());
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
                GestureDetector(
                  onTap: _showAlbumPicker,
                  child: Row(
                    children: [
                      Text(_selectedAlbum?.name ?? "Recents", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    ],
                  ),
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
                          child: isSelected ? Center(child: Text("${_selected.indexOf(asset) + 1}", style: const TextStyle(color: Colors.white, fontSize: 10))) : null,

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
    return SafeArea(
      top: false,
      child: Container(
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
      ),
    );
  }

  void _showAlbumPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Select Album", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _albums.length,
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  return FutureBuilder<int>(
                    future: album.assetCountAsync,
                    builder: (context, snapshot) {
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.folder, color: Colors.white70),
                        ),
                        title: Text(album.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text("${snapshot.data ?? 0} items", style: const TextStyle(color: Colors.white54)),
                        onTap: () {
                          setState(() {
                            _selectedAlbum = album;
                            _previewAsset = null;
                          });
                          _fetchAssets();
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2: MEDIA PREVIEW & EDIT
// ─────────────────────────────────────────────────────────────────────────────
class MediaPreviewStep extends StatefulWidget {
  final List<AssetEntity> assets;
  final Function(int, String, Map<String, dynamic>?, Map<String, dynamic>?) onNext;

  final VoidCallback onBack;

  const MediaPreviewStep({super.key, required this.assets, required this.onNext, required this.onBack});

  @override
  State<MediaPreviewStep> createState() => _MediaPreviewStepState();
}

class _MediaPreviewStepState extends State<MediaPreviewStep> {
  int _selectedFilterIndex = 0;
  final String _overlayText = "";

  final TextEditingController _textEditorController = TextEditingController();
  final TextEditingController _musicSearchController = TextEditingController();
  List<Map<String, dynamic>> _musicResults = [];
  bool _isLoadingMusic = false;
  bool _hasSearchedMusic = false;

  // Image Adjustments
  double _brightness = 0;
  double _contrast = 1;
  double _saturation = 1;
  double _exposure = 0;
  double _blur = 0;
  double _highlights = 0;
  double _shadows = 0;
  double _temp = 0;
  double _tint = 0;
  double _hue = 0;
  double _rotation = 0;
  bool _isFlipped = false;
  
  String? _selectedOverlay;
  String _activeEditTool = "Brightness";

  // Drawing State
  final List<DrawingPath> _paths = [];
  final List<DrawingPath> _redoPaths = [];

  Color _activeColor = Colors.white;
  double _brushSize = 5.0;
  bool _isDrawingMode = false;

  // Stickers State
  final List<StickerItem> _placedStickers = [];

  // Cropped Images State
  final Map<String, File> _croppedFiles = {};


  // Multi-image state
  int _currentAssetIndex = 0;
  final PageController _pageController = PageController();

  // Crop / Aspect Ratio
  double? _aspectRatio = 1.0; // Default to 1:1 (Square)
  BoxFit _fit = BoxFit.cover;

  // Dynamic Effects
  List<Map<String, dynamic>> _dynamicFilters = [];
  List<Map<String, dynamic>> _dynamicOverlays = [];

  VideoPlayerController? _audioController;
  Map<String, dynamic>? _selectedAudio;
  int _musicDuration = 15;
  double _audioStartOffset = 0;
  final List<int> _availableDurations = [5, 15, 30, 45, 60];
  final ScrollController _musicScrollController = ScrollController();
  final GlobalKey _drawingAreaKey = GlobalKey();



  final List<String> _adjustmentTools = [

    "Brightness", "Exposure", "Contrast", "Saturation", "Temperature", "Tint", "Hue", "Highlights", "Shadows", "Blur"
  ];

  @override
  void initState() {
    super.initState();
    _loadEffects();
  }

  Future<void> _loadEffects() async {
    try {
      final repo = context.read<FeedRepositoryImpl>();
      final effects = await repo.fetchEffects();
      setState(() {
        _dynamicFilters = effects['filters'] ?? [];
        _dynamicOverlays = effects['overlays'] ?? [];
        
        // Add fallback stickers if empty for better UX
        if (_dynamicOverlays.isEmpty) {
          _dynamicOverlays = [
            {'type': 'icon', 'value': 'star', 'name': 'Star'},
            {'type': 'icon', 'value': 'favorite', 'name': 'Heart'},
            {'type': 'icon', 'value': 'emoji_emotions', 'name': 'Smile'},
            {'type': 'icon', 'value': 'music_note', 'name': 'Music'},
            {'type': 'icon', 'value': 'location_on', 'name': 'Place'},
            {'type': 'icon', 'value': 'celebration', 'name': 'Party'},
            {'type': 'icon', 'value': 'bolt', 'name': 'Energy'},
            {'type': 'icon', 'value': 'local_fire_department', 'name': 'Fire'},
          ];
        }

        if (_dynamicFilters.isNotEmpty && _selectedFilterIndex >= _dynamicFilters.length) {
          _selectedFilterIndex = 0;
        }
      });

    } catch (e) {
      debugPrint("Load Effects Error: $e");
    }
  }

  Future<void> _cropImage() async {
    try {
      final asset = widget.assets[_currentAssetIndex];
      
      // Safety check: ImageCropper only supports photos
      if (asset.type != AssetType.image) {
        if (mounted) {
          BubbleNotification.show(context, "Cropping is only available for photos", type: NotificationType.info);
        }
        return;
      }

      final file = await asset.file;
      if (file == null) {
        debugPrint("Crop Error: Asset file is null");
        return;
      }

      debugPrint("Starting crop for: ${file.path}");
      
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            activeControlsWidgetColor: Colors.blueAccent,
            backgroundColor: Colors.black,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        debugPrint("Crop Success: ${croppedFile.path}");
        setState(() {
          _croppedFiles[asset.id] = File(croppedFile.path);
        });
      } else {
        debugPrint("Crop Cancelled by user");
      }
    } catch (e) {
      debugPrint("Image Cropping Error: $e");
      if (mounted) {
        BubbleNotification.show(context, "Could not open crop tool: $e", type: NotificationType.error);
      }
    }
  }


  Future<void> _initAudio(String url, {double startAt = 0}) async {
    await _disposeAudio();
    _audioController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _audioController!.initialize();
      await _audioController!.setLooping(true);
      await _audioController!.seekTo(Duration(milliseconds: (startAt * 1000).toInt()));
      await _audioController!.play();
      setState(() {});
    } catch (e) {
      debugPrint("Audio Playback Error: $e");
    }
  }


  Future<void> _disposeAudio() async {
    if (_audioController != null) {
      await _audioController!.pause();
      await _audioController!.dispose();
      _audioController = null;
    }
  }

  @override
  void dispose() {
    _disposeAudio();
    _textEditorController.dispose();
    _musicSearchController.dispose();
    _musicScrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, colorScheme),
          Expanded(
            child: Stack(
              key: _drawingAreaKey,
              alignment: Alignment.center,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _aspectRatio ?? 1.0,
                    child: ClipRect(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: _isDrawingMode ? const NeverScrollableScrollPhysics() : null,
                        itemCount: widget.assets.length,
                        onPageChanged: (idx) => setState(() => _currentAssetIndex = idx),
                        itemBuilder: (context, index) {
                          return Transform(

                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..rotateZ(_rotation)
                                ..scaleByDouble(_isFlipped ? -1.0 : 1.0, 1.0, 1.0),
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: _blur, sigmaY: _blur),
                                child: ColorFiltered(
                                  colorFilter: _DetailsFilters.filters[_selectedFilterIndex].filter,
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.matrix(_calculateAdjustmentMatrix()),
                                    child: _croppedFiles.containsKey(widget.assets[index].id)
                                      ? Image.file(_croppedFiles[widget.assets[index].id]!, fit: _fit)
                                      : FloqGalleryImage(asset: widget.assets[index], fit: _fit, highRes: true),


                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),


                
                // Carousel Indicator (Instagram-like)
                if (widget.assets.length > 1)
                  Positioned(
                    bottom: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.assets.length, (index) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentAssetIndex == index 
                                ? Colors.blueAccent 
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                        );
                      }),
                    ),
                  ),

                // Page Counter (Instagram-like 1/2)
                if (widget.assets.length > 1)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_currentAssetIndex + 1}/${widget.assets.length}",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                
                // Drawing Layer
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: _isDrawingMode ? (details) {
                      setState(() {
                        RenderBox renderBox = _drawingAreaKey.currentContext?.findRenderObject() as RenderBox;
                        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                        _paths.add(DrawingPath(points: [localPosition], color: _activeColor, width: _brushSize));
                        _redoPaths.clear();
                      });
                    } : null,
                    onPanUpdate: _isDrawingMode ? (details) {
                      setState(() {
                        RenderBox renderBox = _drawingAreaKey.currentContext?.findRenderObject() as RenderBox;
                        Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                        if (_paths.isNotEmpty && !_paths.last.isComplete) {
                          _paths.last.points.add(localPosition);
                        }
                      });
                    } : null,
                    onPanEnd: _isDrawingMode ? (_) {
                      setState(() => _paths.last.isComplete = true);
                    } : null,
                    child: IgnorePointer(
                      ignoring: true, // CustomPaint doesn't need touch, GestureDetector handles it
                      child: CustomPaint(
                        painter: DrawingPainter(paths: _paths),
                      ),
                    ),
                  ),
                ),


                // Stickers Layer
                ..._placedStickers.map((sticker) => Positioned(
                  left: sticker.position.dx,
                  top: sticker.position.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        sticker.position += details.delta;
                      });
                    },
                    onLongPress: () {
                      setState(() => _placedStickers.remove(sticker));
                    },
                    child: Transform.rotate(
                      angle: sticker.rotation,
                      child: Transform.scale(
                        scale: sticker.scale,
                        child: sticker.isIcon 
                          ? Icon(sticker.icon, color: Colors.white, size: 80)
                          : sticker.isText
                            ? Text(sticker.text ?? "", style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, decoration: TextDecoration.none))
                            : Image.network(sticker.url!, width: 100, height: 100, errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white38)),



                      ),
                    ),
                  ),
                )),

                if (_selectedOverlay != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: _getOverlayWidget(),
                      ),
                    ),
                  ),

                if (_selectedAudio != null)
                  Positioned(
                    bottom: 110,
                    left: 0, right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedAudio = null);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white12, width: 0.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: _selectedAudio!['cover'] != null 
                                  ? Image.network(_selectedAudio!['cover']!, width: 24, height: 24, fit: BoxFit.cover)
                                  : Container(
                                      width: 24, height: 24, 
                                      color: Colors.blueAccent,
                                      child: const Icon(Icons.music_note, color: Colors.white, size: 14)
                                    ),
                              ),
                              const SizedBox(width: 10),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
                                child: Text(
                                  "${_selectedAudio!['title']} • ${_selectedAudio!['artist']}",
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  _disposeAudio();
                                  setState(() => _selectedAudio = null);
                                },
                                child: const Icon(Icons.close, color: Colors.white54, size: 16)
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Drawing Controls Overlay
                if (_isDrawingMode)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_paths.isNotEmpty) {
                              setState(() {
                                _redoPaths.add(_paths.removeLast());
                              });
                            }
                          },
                          icon: Icon(Icons.undo, color: _paths.isNotEmpty ? Colors.white : Colors.white38),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_redoPaths.isNotEmpty) {
                              setState(() {
                                _paths.add(_redoPaths.removeLast());
                              });
                            }
                          },
                          icon: Icon(Icons.redo, color: _redoPaths.isNotEmpty ? Colors.white : Colors.white38),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _paths.clear();
                            _redoPaths.clear();
                          }),
                          icon: const Icon(Icons.delete_sweep, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _isDrawingMode = false),
                          icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 32),
                        ),
                      ],
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


  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: widget.onBack, icon: const Icon(Icons.close, color: Colors.white)),
          const Spacer(),
          IconButton(onPressed: () => _showEditorSheet(context, "Audio"), icon: const Icon(Icons.music_note, color: Colors.white)),
          IconButton(onPressed: () => _showEditorSheet(context, "Draw"), icon: const Icon(Icons.brush, color: Colors.white)),
          IconButton(onPressed: () => _showEditorSheet(context, "Text"), icon: const Icon(Icons.text_fields, color: Colors.white)),
          IconButton(onPressed: () => _showEditorSheet(context, "Stickers"), icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white)),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: TextButton(
              onPressed: () {
                _disposeAudio();
                widget.onNext(_selectedFilterIndex, _overlayText, _selectedAudio, {
                  'brightness': _brightness,
                  'contrast': _contrast,
                  'saturation': _saturation,
                  'exposure': _exposure,
                  'highlights': _highlights,
                  'shadows': _shadows,
                  'blur': _blur,
                  'temp': _temp,
                  'tint': _tint,
                  'hue': _hue,
                  'rotation': _rotation,
                  'isFlipped': _isFlipped,
                  'aspectRatio': _aspectRatio,
                  'fit': _fit,
                  'overlay': _selectedOverlay,
                  'paths': _paths,
                   'stickers': _placedStickers,
                   'croppedFiles': _croppedFiles,
                   'musicDuration': _musicDuration,
                 });


              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: Text("Next", style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditToolbar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 180,
        color: Colors.black,
        child: Column(
          children: [
            if (_adjustmentTools.contains(_activeEditTool) || _activeEditTool == "Adjust") Expanded(child: _buildAdjustSliders()),
            if (_activeEditTool == "Filters") Expanded(child: _buildFiltersList()),
            if (_activeEditTool == "Stickers") Expanded(child: _buildStickersList()),
            if (_activeEditTool == "Transform") Expanded(child: _buildTransformTools()),
            _buildToolSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustSliders() {
    final List<Map<String, dynamic>> editTools = [
      {"name": "Brightness", "icon": Icons.brightness_6, "val": _brightness, "min": -0.5, "max": 0.5},
      {"name": "Exposure", "icon": Icons.exposure, "val": _exposure, "min": -0.5, "max": 0.5},
      {"name": "Contrast", "icon": Icons.contrast, "val": _contrast, "min": 0.5, "max": 1.5},
      {"name": "Saturation", "icon": Icons.palette, "val": _saturation, "min": 0.0, "max": 2.0},
      {"name": "Temperature", "icon": Icons.device_thermostat, "val": _temp, "min": -1.0, "max": 1.0},
      {"name": "Tint", "icon": Icons.opacity, "val": _tint, "min": -1.0, "max": 1.0},
      {"name": "Hue", "icon": Icons.color_lens, "val": _hue, "min": -1.0, "max": 1.0},
      {"name": "Highlights", "icon": Icons.wb_sunny_outlined, "val": _highlights, "min": -0.5, "max": 0.5},
      {"name": "Shadows", "icon": Icons.nights_stay_outlined, "val": _shadows, "min": -0.5, "max": 0.5},
      {"name": "Blur", "icon": Icons.blur_on, "val": _blur, "min": 0.0, "max": 10.0},
    ];

    final currentTool = editTools.firstWhere((t) => t['name'] == _activeEditTool, orElse: () => editTools.first);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              const SizedBox(width: 20),
              Icon(currentTool['icon'] as IconData, color: Colors.white70, size: 18),
              Expanded(
                child: Slider(
                  value: currentTool['val'],
                  min: currentTool['min'],
                  max: currentTool['max'],
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    setState(() {
                      if (_activeEditTool == "Brightness" || _activeEditTool == "Adjust") _brightness = val;
                      if (_activeEditTool == "Exposure") _exposure = val;
                      if (_activeEditTool == "Contrast") _contrast = val;
                      if (_activeEditTool == "Saturation") _saturation = val;
                      if (_activeEditTool == "Highlights") _highlights = val;
                      if (_activeEditTool == "Shadows") _shadows = val;
                      if (_activeEditTool == "Blur") _blur = val;
                      if (_activeEditTool == "Temperature") _temp = val;
                      if (_activeEditTool == "Tint") _tint = val;
                      if (_activeEditTool == "Hue") _hue = val;
                    });
                  },
                ),
              ),
              Text(
                currentTool['val'].toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: editTools.length,
            itemBuilder: (context, index) {
              final tool = editTools[index];
              final isSelected = _activeEditTool == tool['name'] || (_activeEditTool == "Adjust" && index == 0);
              return GestureDetector(
                onTap: () => setState(() => _activeEditTool = tool['name']),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tool['name'],
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white54,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    )
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _DetailsFilters.filters.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedFilterIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilterIndex = index),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                      child: ColorFiltered(
                        colorFilter: _DetailsFilters.filters[index].filter,
                        child: FloqGalleryImage(asset: widget.assets.first),
                      ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_DetailsFilters.filters[index].name, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStickersList() {
    if (_dynamicOverlays.isEmpty) {
      return const Center(child: Text("No overlays available", style: TextStyle(color: Colors.white54, fontSize: 12)));
    }
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _dynamicOverlays.length,
      itemBuilder: (context, index) {
        final sticker = _dynamicOverlays[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _placedStickers.add(StickerItem(
                isIcon: sticker['type'] == 'icon',
                icon: sticker['type'] == 'icon' ? _getIconData(sticker['value']) : null,
                url: sticker['type'] == 'url' ? sticker['value'] : null,
                position: const Offset(150, 150),
              ));
            });
          },
          child: Container(
            width: 60,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: sticker['type'] == 'icon' 
              ? Icon(_getIconData(sticker['value']), color: Colors.white) 
              : Image.network(sticker['value'], fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  Widget _buildTransformTools() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _transformBtn(Icons.rotate_right, "Rotate", () => setState(() => _rotation += 1.5708)),
            _transformBtn(Icons.flip, "Flip", () => setState(() => _isFlipped = !_isFlipped)),
            _transformBtn(Icons.crop, "Crop", _cropImage),
            _transformBtn(Icons.crop_free, "Fit/Fill", () => setState(() => _fit = _fit == BoxFit.cover ? BoxFit.contain : BoxFit.cover)),

          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _aspectBtn("1:1", 1.0),
            _aspectBtn("4:5", 4 / 5),
            _aspectBtn("16:9", 16 / 9),
            _aspectBtn("Original", null),
          ],
        ),
      ],
    );
  }

  Widget _aspectBtn(String label, double? ratio) {
    final isSelected = _aspectRatio == ratio;
    return GestureDetector(
      onTap: () => setState(() => _aspectRatio = ratio),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ),
    );
  }

  Widget _buildToolSelector() {
    final tools = ["Adjust", "Filters", "Stickers", "Transform"];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          final isSelected = _activeEditTool == tool;
          return GestureDetector(
            onTap: () => setState(() => _activeEditTool = tool),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: Text(
                tool,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  void _showEditorSheet(BuildContext context, String tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: tool == "Text" || tool == "Audio" || tool == "Stickers" ? MediaQuery.of(context).size.height * 0.85 : 420,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
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
                      if (tool == "Text" && _textEditorController.text.isNotEmpty) {
                        setState(() {
                          _placedStickers.add(StickerItem(
                            text: _textEditorController.text,
                            isText: true,
                            position: Offset(MediaQuery.of(context).size.width / 2 - 50, MediaQuery.of(context).size.height / 3),
                          ));
                          _textEditorController.clear();
                        });
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
      ),
    );
  }

  Widget _buildToolContent(String tool) {
    if (tool == "Filters") {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: _DetailsFilters.filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ColorFiltered(
                        colorFilter: _DetailsFilters.filters[index].filter,
                        child: FloqGalleryImage(asset: widget.assets.first, fit: BoxFit.cover),
                      ),

                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_DetailsFilters.filters[index].name, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      );
    }
    
    if (tool == "Audio") {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          if (!_hasSearchedMusic && !_isLoadingMusic) {
             _hasSearchedMusic = true;
             _fetchMusic(setSheetState);
          }

          return Column(
            children: [
              if (_selectedAudio != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Selected: ${_selectedAudio!['title']}",
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _disposeAudio();
                            _selectedAudio = null;
                          });
                          setState(() {});
                        },
                        child: const Text("Remove", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _musicSearchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search music...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), 
                      borderSide: BorderSide.none
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), 
                      borderSide: BorderSide(color: Colors.white10, width: 1)
                    ),
                  ),
                  onChanged: (val) => _fetchMusic(setSheetState, query: val),
                ),
              ),
              Expanded(
                child: _isLoadingMusic 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _musicResults.isEmpty
                    ? Center(child: Text("No songs found", style: GoogleFonts.poppins(color: Colors.white38)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _musicResults.length,
                        itemBuilder: (context, index) {
                          final track = _musicResults[index];
                          final title = track['title'] ?? 'Unknown';
                          final artist = track['artist'] ?? 'Unknown';
                          final trackUrl = track['url'] ?? '';
                          final isSelected = _selectedAudio?['url'] == trackUrl;

                          
                          return Column(
                            children: [
                              ListTile(
                                onTap: () {
                                  setSheetState(() {
                                     if (isSelected) {
                                       _disposeAudio();
                                       _selectedAudio = null;
                                     } else {
                                       _selectedAudio = {
                                         "title": title, 
                                         "artist": artist,
                                         "url": track['url'] ?? '',
                                       };
                                       _initAudio(track['url'] ?? '');
                                     }
                                  });
                                  setState(() {}); 
                                },
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: track['cover'] != null 
                                    ? Image.network(track['cover'], width: 45, height: 45, fit: BoxFit.cover)
                                    : Container(
                                        width: 45, height: 45,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.blueAccent : Colors.white10, 
                                        ),
                                        child: Icon(isSelected ? Icons.music_note : Icons.music_video, color: Colors.white70),
                                      ),
                                ),
                                title: Text(title, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white, fontSize: 14)),
                                subtitle: Text(artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                trailing: Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, color: isSelected ? Colors.blueAccent : Colors.white38),
                              ),
                              
                              // Duration & Scrubber (Instagram-style)
                              if (isSelected) ...[
                                const Divider(color: Colors.white12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text("Duration:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: SizedBox(
                                              height: 32,
                                              child: ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: _availableDurations.length,
                                                itemBuilder: (context, dIdx) {
                                                  final d = _availableDurations[dIdx];
                                                  final isSel = _musicDuration == d;
                                                  return GestureDetector(
                                                    onTap: () => setSheetState(() => _musicDuration = d),
                                                    child: Container(
                                                      margin: const EdgeInsets.only(right: 8),
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      decoration: BoxDecoration(
                                                        color: isSel ? Colors.blueAccent : Colors.white10,
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: Text("${d}s", style: TextStyle(color: isSel ? Colors.white : Colors.white70, fontSize: 11)),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Select part of song:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                                          Text(
                                            "${_audioStartOffset.toInt()}s - ${(_audioStartOffset + _musicDuration).toInt()}s",
                                            style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      // Instagram-style Waveform Scrubber
                                      SizedBox(
                                        height: 60,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // The scrolling waveform
                                            NotificationListener<ScrollNotification>(
                                              onNotification: (scroll) {
                                                final totalSeconds = _audioController?.value.duration.inSeconds ?? 30;
                                                final maxScroll = _musicScrollController.position.maxScrollExtent;
                                                if (maxScroll > 0) {
                                                  final newOffset = (scroll.metrics.pixels / maxScroll) * (totalSeconds - _musicDuration);
                                                  setSheetState(() => _audioStartOffset = newOffset.clamp(0.0, totalSeconds - _musicDuration.toDouble()));
                                                  _audioController?.seekTo(Duration(seconds: _audioStartOffset.toInt()));
                                                }
                                                return true;
                                              },
                                              child: ListView.builder(
                                                controller: _musicScrollController,
                                                scrollDirection: Axis.horizontal,
                                                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 20),
                                                itemCount: (_audioController?.value.duration.inSeconds ?? 30),
                                                itemBuilder: (context, wIdx) {
                                                  final h = 10 + (math.Random(wIdx).nextDouble() * 30);
                                                  return Container(
                                                    width: 4,
                                                    height: h,
                                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white24,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            // The fixed selector window
                                            IgnorePointer(
                                              child: Container(
                                                width: 40,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  border: Border.symmetric(
                                                    vertical: BorderSide(color: Colors.blueAccent, width: 2),
                                                  ),
                                                  color: Colors.blueAccent.withValues(alpha: 0.1),
                                                ),
                                              ),
                                            ),
                                            // Center indicator line
                                            IgnorePointer(
                                              child: Container(width: 2, height: 60, color: Colors.blueAccent),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],


                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
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
        ),
      );
    }

    if (tool == "Adjust") {
      final List<Map<String, dynamic>> editTools = [
        {"name": "Brightness", "icon": Icons.brightness_6, "val": _brightness, "min": -0.5, "max": 0.5},
        {"name": "Exposure", "icon": Icons.exposure, "val": _exposure, "min": -0.5, "max": 0.5},
        {"name": "Contrast", "icon": Icons.contrast, "val": _contrast, "min": 0.5, "max": 1.5},
        {"name": "Saturation", "icon": Icons.palette, "val": _saturation, "min": 0, "max": 2},
        {"name": "Highlights", "icon": Icons.wb_sunny_outlined, "val": _highlights, "min": -0.5, "max": 0.5},
        {"name": "Shadows", "icon": Icons.nights_stay_outlined, "val": _shadows, "min": -0.5, "max": 0.5},
        {"name": "Blur", "icon": Icons.blur_on, "val": _blur, "min": 0, "max": 10},
      ];

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final currentTool = editTools.firstWhere((t) => t['name'] == _activeEditTool, orElse: () => editTools.first);
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                _activeEditTool,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Slider(
                value: currentTool['val'],
                min: currentTool['min'],
                max: currentTool['max'],
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.white10,
                onChanged: (val) {
                  setSheetState(() {
                    if (_activeEditTool == "Brightness") _brightness = val;
                    if (_activeEditTool == "Exposure") _exposure = val;
                    if (_activeEditTool == "Contrast") _contrast = val;
                    if (_activeEditTool == "Saturation") _saturation = val;
                    if (_activeEditTool == "Highlights") _highlights = val;
                    if (_activeEditTool == "Shadows") _shadows = val;
                    if (_activeEditTool == "Blur") _blur = val;
                  });
                  setState(() {});
                },
              ),
              const Spacer(),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: editTools.length,
                  itemBuilder: (context, index) {
                    final t = editTools[index];
                    final isSelected = _activeEditTool == t['name'];
                    return GestureDetector(
                      onTap: () => setSheetState(() => _activeEditTool = t['name']),
                      child: Container(
                        width: 75,
                        margin: const EdgeInsets.only(right: 15),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05),
                              ),
                              child: Icon(t['icon'], color: isSelected ? Colors.white : Colors.white70, size: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(t['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    }

    if (tool == "Transform") {
      final isVideo = widget.assets[_currentAssetIndex].type != AssetType.image;
      
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _transformBtn(Icons.rotate_right, "Rotate", () => setState(() => _rotation += 1.5708)),
              _transformBtn(Icons.flip, "Flip", () => setState(() => _isFlipped = !_isFlipped)),
              _transformBtn(
                Icons.crop_rotate, 
                "Crop", 
                _cropImage,
                color: isVideo ? Colors.white24 : Colors.white
              ),
              _transformBtn(
                _fit == BoxFit.cover ? Icons.fullscreen_exit : Icons.fullscreen, 
                "Fit/Fill", 
                () => setState(() => _fit = _fit == BoxFit.cover ? BoxFit.contain : BoxFit.cover)
              ),
            ],
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _aspectRatioBtn("1:1", 1/1)),
                const SizedBox(width: 8),
                Expanded(child: _aspectRatioBtn("4:5", 4/5)),
                const SizedBox(width: 8),
                Expanded(child: _aspectRatioBtn("16:9", 16/9)),
                const SizedBox(width: 8),
                Expanded(child: _aspectRatioBtn("Original", null)),
              ],
            ),
          ),
        ],
      );
    }

    if (tool == "Draw") {
      return Column(
        children: [
          const SizedBox(height: 20),
          _buildColorPicker(),
          const SizedBox(height: 30),
          Text("Brush Size: ${_brushSize.toInt()}", style: const TextStyle(color: Colors.white70)),
          Slider(
            value: _brushSize,
            min: 1, max: 20,
            activeColor: _activeColor,
            onChanged: (v) => setState(() => _brushSize = v),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isDrawingMode = true);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.brush),
            label: const Text("Start Drawing"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(200, 50),
            ),
          ),
          const SizedBox(height: 40),
        ],
      );
    }

    if (tool == "Stickers") {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [Tab(text: "Emojis"), Tab(text: "Graphic")],
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                    itemCount: 50,
                    itemBuilder: (context, index) {
                      final emoji = String.fromCharCode(0x1F600 + index);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _placedStickers.add(StickerItem(
                            icon: Icons.face, // Placeholder for text rendering if complex
                            text: emoji,
                            isIcon: false,
                            isText: true,
                            position: const Offset(150, 200),
                          )));
                          Navigator.pop(context);
                        },
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
                      );
                    },
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: _dynamicOverlays.length,
                    itemBuilder: (context, index) {
                      final o = _dynamicOverlays[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _placedStickers.add(StickerItem(
                            url: o['value'],
                            isIcon: o['type'] == 'icon',
                            icon: o['type'] == 'icon' ? _getIconData(o['value']) : null,
                            position: const Offset(100, 150),
                          )));
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                          child: o['type'] == 'icon' ? Icon(_getIconData(o['value']), color: Colors.white) : Image.network(o['value']),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Text("$tool settings coming soon!", style: const TextStyle(color: Colors.white54)),
    );
  }


  Widget _getOverlayWidget() {
    if (_selectedOverlay == null) return const SizedBox.shrink();
    final o = _dynamicOverlays.firstWhere((e) => e['id'] == _selectedOverlay, orElse: () => {});
    if (o.isEmpty) return const SizedBox.shrink();

    if (o['type'] == 'icon') {
      return Icon(
        _getIconData(o['value']),
        color: Colors.white.withValues(alpha: 0.3),
        size: 200,
      );
    } else {
      return Image.network(o['value'], width: 300, height: 300, color: Colors.white.withValues(alpha: 0.3));
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'favorite': 
      case 'heart': return Icons.favorite;
      case 'star': return Icons.star;
      case 'music_note':
      case 'music': return Icons.music_note;
      case 'block': return Icons.block;
      case 'emoji_emotions':
      case 'face':
      case 'smile': return Icons.emoji_emotions;
      case 'celebration':
      case 'party': return Icons.celebration;
      case 'local_fire_department':
      case 'fire':
      case 'fire_truck': return Icons.local_fire_department;
      case 'bolt': return Icons.bolt;
      case 'location_on':
      case 'location': return Icons.location_on;
      case 'check_circle': return Icons.check_circle;
      case 'info': return Icons.info;
      case 'warning': return Icons.warning;
      case 'camera': return Icons.camera_alt;
      case 'videocam': return Icons.videocam;
      default: return Icons.auto_awesome;
    }
  }

  List<double> _calculateAdjustmentMatrix() {
    double b = (_brightness + _exposure + _highlights * 0.5 + _shadows * 0.2) * 255;
    double contrast = _contrast;
    double saturation = _saturation;
    
    // Temperature & Tint
    double tR = _temp * 30;
    double tG = _tint * 20;
    double tB = -_temp * 30;

    // Hue Rotation approx
    double h = _hue * 3.14159; // range -pi to pi
    double cosH = math.cos(h);
    double sinH = math.sin(h);
    
    const double rwgt = 0.3086;
    const double gwgt = 0.6094;
    const double bwgt = 0.0820;

    double invSat = 1 - saturation;
    double R = invSat * rwgt;
    double G = invSat * gwgt;
    double B = invSat * bwgt;

    // Base matrix with contrast and saturation
    List<double> matrix = [
      (R + saturation) * contrast, G * contrast, B * contrast, 0, b + tR,
      R * contrast, (G + saturation) * contrast, B * contrast, 0, b + tG,
      R * contrast, G * contrast, (B + saturation) * contrast, 0, b + tB,
      0, 0, 0, 1, 0,
    ];

    if (_hue != 0) {
       // Apply hue rotation to the primary color components
       // This is a simplified matrix multiplication for hue
       double r1 = matrix[0] * cosH + matrix[1] * sinH;
       double r2 = matrix[1] * cosH - matrix[0] * sinH;
       matrix[0] = r1; matrix[1] = r2;
    }

    return matrix;
  }

  Widget _transformBtn(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return Column(
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon, color: color)),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.54), fontSize: 10)),
      ],
    );
  }


  Widget _aspectRatioBtn(String label, double? ratio) {
    final isSelected = _aspectRatio == ratio;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          if (ratio == null) {
            _aspectRatio = 1.0;
            _rotation = 0;
            _isFlipped = false;
            _fit = BoxFit.cover;
          } else {
            _aspectRatio = ratio;
          }
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.white24),
        backgroundColor: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.zero,
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white, fontSize: 11)),
    );
  }


  Widget _buildColorPicker() {
    final colors = [Colors.white, Colors.black, Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final c = colors[index];
          return GestureDetector(
            onTap: () => setState(() => _activeColor = c),
            child: Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: _activeColor == c ? Theme.of(context).colorScheme.primary : Colors.white24, width: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchMusic(void Function(void Function()) setSheetState, {String? query}) async {
    setSheetState(() => _isLoadingMusic = true);
    
    try {
      final repo = context.read<FeedRepositoryImpl>();
      final results = await repo.getTrendingMusic(query: query);
      
      setSheetState(() {
        _musicResults = results;
        _isLoadingMusic = false;
      });
    } catch (e) {
      setSheetState(() => _isLoadingMusic = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3: POST DETAILS
// ─────────────────────────────────────────────────────────────────────────────
class PostDetailsStep extends StatefulWidget {
  final List<AssetEntity> assets;
  final TextEditingController captionController;
  final PostType selectedType;
  final VoidCallback onShare;
  final VoidCallback onBack;
  final int selectedFilterIndex;
  final String overlayText;
   final Map<String, dynamic>? selectedAudio;

   final Map<String, dynamic>? adjustments;
   final Map<String, File> croppedFiles;
 
   const PostDetailsStep({
     super.key, 
     required this.assets, 
     required this.captionController,
     required this.selectedType,
     required this.onShare,
     required this.onBack,
     this.selectedFilterIndex = 0,
     this.overlayText = "",
     this.selectedAudio,
     this.adjustments,
     this.croppedFiles = const {},
   });


  @override
  State<PostDetailsStep> createState() => _PostDetailsStepState();
}

class _FilterItem {
  final String name;
  final ColorFilter filter;
  const _FilterItem(this.name, this.filter);
}

class _DetailsFilters {
  static final List<_FilterItem> filters = [
    const _FilterItem("Original", ColorFilter.mode(Colors.transparent, BlendMode.dst)),
    const _FilterItem("Vintage", ColorFilter.matrix([
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Noir", ColorFilter.matrix([
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Cinematic", ColorFilter.matrix([
      1.1, 0, 0, 0, -20,
      0, 1.0, 0, 0, -20,
      0, 0, 0.9, 0, -20,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Warm", ColorFilter.matrix([
      1.1, 0, 0, 0, 10,
      0, 1.0, 0, 0, 5,
      0, 0, 0.8, 0, -10,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Cool", ColorFilter.matrix([
      0.8, 0, 0, 0, -10,
      0, 1.0, 0, 0, 5,
      0, 0, 1.1, 0, 10,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Faded", ColorFilter.matrix([
      0.9, 0, 0, 0, 20,
      0, 0.9, 0, 0, 20,
      0, 0, 0.9, 0, 20,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Dramatic", ColorFilter.matrix([
      1.5, 0, 0, 0, -50,
      0, 1.5, 0, 0, -50,
      0, 0, 1.5, 0, -50,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Mono", ColorFilter.matrix([
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Invert", ColorFilter.matrix([
      -1, 0, 0, 0, 255,
      0, -1, 0, 0, 255,
      0, 0, -1, 0, 255,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Ocean", ColorFilter.matrix([
      1, 0, 0, 0, 0,
      0, 1.1, 0, 0, 10,
      0, 0, 1.2, 0, 30,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Cyberpunk", ColorFilter.matrix([
      1.2, 0, 0, 0, 20,
      0, 0.8, 0, 0, -20,
      0, 0, 1.5, 0, 50,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Polaroid", ColorFilter.matrix([
      1.1, 0.1, 0.1, 0, 0,
      0.1, 1.0, 0.1, 0, 0,
      0.1, 0.1, 0.9, 0, 30,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Sunset", ColorFilter.matrix([
      1.2, 0, 0, 0, 30,
      0, 1.0, 0, 0, 0,
      0, 0, 0.8, 0, -20,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Forest", ColorFilter.matrix([
      0.9, 0, 0, 0, -10,
      0, 1.2, 0, 0, 20,
      0, 0, 0.9, 0, -10,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Sepia", ColorFilter.matrix([
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ])),
    const _FilterItem("Sky", ColorFilter.mode(Colors.blue, BlendMode.softLight)),
    const _FilterItem("Rose", ColorFilter.mode(Colors.pink, BlendMode.softLight)),
    const _FilterItem("Gold", ColorFilter.mode(Colors.orange, BlendMode.overlay)),
  ];
}

class _PostDetailsStepState extends State<PostDetailsStep> {
  String _myAvatar = "";
  String _myName = "Me";
  int _currentPage = 0;
  String? _selectedLocation;
  final List<UserEntity> _taggedUsers = [];
  bool _isLoadingLocs = false;
  List<dynamic> _locationResults = [];
  final TextEditingController _locSearchController = TextEditingController();
  final TextEditingController _tagSearchController = TextEditingController();
  List<UserEntity> _userResults = [];
  bool _isLoadingUsers = false;



  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  List<double> _calculateFinalMatrix() {
    if (widget.adjustments == null) return [1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0];
    
    double b = ((widget.adjustments!['brightness'] ?? 0) + (widget.adjustments!['exposure'] ?? 0) + (widget.adjustments!['highlights'] ?? 0) * 0.5 + (widget.adjustments!['shadows'] ?? 0) * 0.2) * 255;
    double contrast = widget.adjustments!['contrast'] ?? 1.0;
    double saturation = widget.adjustments!['saturation'] ?? 1.0;
    
    double temp = widget.adjustments!['temp'] ?? 0.0;
    double tint = widget.adjustments!['tint'] ?? 0.0;
    double hue = widget.adjustments!['hue'] ?? 0.0;

    double tR = temp * 30;
    double tG = tint * 20;
    double tB = -temp * 30;

    double h = hue * 3.14159;
    double cosH = math.cos(h);
    double sinH = math.sin(h);
    
    const double rwgt = 0.3086;
    const double gwgt = 0.6094;
    const double bwgt = 0.0820;
    double invSat = 1 - saturation;
    double R = invSat * rwgt;
    double G = invSat * gwgt;
    double B = invSat * bwgt;

    List<double> matrix = [
      (R + saturation) * contrast, G * contrast, B * contrast, 0, b + tR,
      R * contrast, (G + saturation) * contrast, B * contrast, 0, b + tG,
      R * contrast, G * contrast, (B + saturation) * contrast, 0, b + tB,
      0, 0, 0, 1, 0,
    ];

    if (hue != 0) {
       double r1 = matrix[0] * cosH + matrix[1] * sinH;
       double r2 = matrix[1] * cosH - matrix[0] * sinH;
       matrix[0] = r1; matrix[1] = r2;
    }

    return matrix;
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
    final colorScheme = Theme.of(context).colorScheme;
    
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
                              AspectRatio(
                                aspectRatio: widget.adjustments?['aspectRatio'] ?? 1.0,
                                child: ClipRect(
                                  child: PageView.builder(
                                    itemCount: widget.assets.length,
                                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                                    itemBuilder: (context, index) {

                                      return Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateZ(widget.adjustments?['rotation'] ?? 0)
                                          ..scaleByDouble((widget.adjustments?['isFlipped'] ?? false) ? -1.0 : 1.0, 1.0, 1.0),
                                        child: ImageFiltered(
                                          imageFilter: ImageFilter.blur(sigmaX: widget.adjustments?['blur'] ?? 0, sigmaY: widget.adjustments?['blur'] ?? 0),
                                          child: ColorFiltered(
                                            colorFilter: _DetailsFilters.filters[widget.selectedFilterIndex].filter,
                                            child: ColorFiltered(
                                              colorFilter: ColorFilter.matrix(_calculateFinalMatrix()),
                                               child: widget.croppedFiles.containsKey(widget.assets[index].id)
                                                 ? Image.file(widget.croppedFiles[widget.assets[index].id]!, fit: widget.adjustments?['fit'] ?? BoxFit.cover)
                                                 : FloqGalleryImage(asset: widget.assets[index], fit: widget.adjustments?['fit'] ?? BoxFit.cover),


                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Dots Indicator
                              if (widget.assets.length > 1)
                                Positioned(
                                  bottom: 12,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(widget.assets.length, (idx) => Container(
                                      width: 6, height: 6,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentPage == idx ? Colors.blueAccent : Colors.white24,
                                      ),
                                    )),
                                  ),
                                ),

                              if (widget.adjustments?['paths'] != null)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: DrawingPainter(paths: widget.adjustments!['paths'] as List<DrawingPath>),
                                  ),
                                ),
                              if (widget.adjustments?['stickers'] != null)
                                ... (widget.adjustments!['stickers'] as List<StickerItem>).map((sticker) => Positioned(
                                  left: sticker.position.dx * 0.5, // Scale down for preview
                                  top: sticker.position.dy * 0.5,
                                  child: Transform.rotate(
                                    angle: sticker.rotation,
                                    child: Transform.scale(
                                      scale: sticker.scale * 0.6,
                                      child: sticker.isIcon 
                                        ? Icon(sticker.icon, color: Colors.white, size: 80)
                                        : (sticker.isText ? Text(sticker.text!, style: const TextStyle(fontSize: 40)) : Image.network(sticker.url!, width: 100, height: 100)),
                                    ),
                                  ),
                                )),
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

                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: widget.captionController,
                              maxLines: 3,
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                hintText: "Write a caption...",
                                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
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
            _listTile(Icons.location_on_outlined, _selectedLocation ?? "Add location", onTap: _showLocationPicker),
            _listTile(Icons.person_add_alt, _taggedUsers.isEmpty ? "Tag people" : "${_taggedUsers.length} people tagged", onTap: _showTagPicker),
            _listTile(
              Icons.music_note, 
              widget.selectedAudio != null ? "${widget.selectedAudio!['title']}" : "Add music",
              subtitle: widget.selectedAudio != null ? widget.selectedAudio!['artist'] : null,
              onTap: () => BubbleNotification.show(context, "Music selection is in the previous step", type: NotificationType.info),
            ),
            const Divider(),

            
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: widget.onShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "Share Post", 
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, 
                      color: colorScheme.onPrimary, 
                      fontSize: 16,
                      letterSpacing: 0.5,
                    )
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchLocations(String query, StateSetter setSheetState) async {
    if (query.isEmpty) return;
    setSheetState(() => _isLoadingLocs = true);
    try {
      final response = await http.get(
        Uri.parse("https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5"),
        headers: {'User-Agent': 'FloqApp/1.0'}
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setSheetState(() {
          _locationResults = data;
          _isLoadingLocs = false;
        });
      }
    } catch (e) {
      if (mounted) setSheetState(() => _isLoadingLocs = false);
    }
  }

  Future<void> _getCurrentLocation(StateSetter setSheetState) async {
    setSheetState(() => _isLoadingLocs = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) BubbleNotification.show(context, "Location services are disabled", type: NotificationType.error);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) BubbleNotification.show(context, "Location permissions are denied", type: NotificationType.error);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) BubbleNotification.show(context, "Location permissions are permanently denied", type: NotificationType.error);
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(pos.latitude, pos.longitude);
      
      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        String locName = place.locality ?? place.subLocality ?? place.name ?? "Unknown Location";
        if (mounted) {
          setState(() => _selectedLocation = locName);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) BubbleNotification.show(context, "Could not get location: $e", type: NotificationType.error);
    } finally {
      if (mounted) setSheetState(() => _isLoadingLocs = false);
    }
  }





  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              TextField(
                controller: _locSearchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search location...",
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => _searchLocations(val, setSheetState),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blueAccent),
                title: const Text("Use Current Location", style: TextStyle(color: Colors.white)),
                onTap: () => _getCurrentLocation(setSheetState),
              ),
              if (_isLoadingLocs) const Center(child: CircularProgressIndicator()),
              Expanded(
                child: ListView.builder(
                  itemCount: _locationResults.length,
                  itemBuilder: (context, index) {
                    final loc = _locationResults[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.white54),
                      title: Text(loc['display_name'], style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2),
                      onTap: () {
                        setState(() => _selectedLocation = loc['display_name'].split(',')[0]);
                        Navigator.pop(context);
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

  Future<void> _searchUsers(String query, StateSetter setSheetState) async {
    if (query.isEmpty) return;
    setSheetState(() => _isLoadingUsers = true);
    try {
      final repo = context.read<UsersRepository>();
      final users = await repo.searchUsers(query);
      setSheetState(() {
        _userResults = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setSheetState(() => _isLoadingUsers = false);
    }
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              TextField(
                controller: _tagSearchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search people...",
                  prefixIcon: const Icon(Icons.person_search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => _searchUsers(val, setSheetState),
              ),
              const SizedBox(height: 20),
              if (_isLoadingUsers) const Center(child: CircularProgressIndicator()),
              Expanded(
                child: ListView.builder(
                  itemCount: _userResults.length,
                  itemBuilder: (context, index) {
                    final user = _userResults[index];
                    final isTagged = _taggedUsers.any((u) => u.id == user.id);
                    return ListTile(
                      leading: FloqAvatar(imageUrl: user.profileUrl, name: user.name, radius: 20),
                      title: Text(user.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text("@${user.id.substring(0, math.min(8, user.id.length))}", style: const TextStyle(color: Colors.white38)),
                      trailing: Icon(isTagged ? Icons.check_circle : Icons.add_circle_outline, color: isTagged ? Colors.blueAccent : Colors.white24),
                      onTap: () {

                        setState(() {
                          if (isTagged) {
                            _taggedUsers.removeWhere((u) => u.id == user.id);
                          } else {
                            _taggedUsers.add(user);
                          }
                        });
                        setSheetState(() {});
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

  Widget _listTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.white70),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white38),
      onTap: onTap,
    );
  }

}

class FloqGalleryImage extends StatelessWidget {
  final AssetEntity asset;
  final BoxFit fit;
  final bool highRes;
  const FloqGalleryImage({super.key, required this.asset, this.fit = BoxFit.cover, this.highRes = false});

  @override
  Widget build(BuildContext context) {
    return AssetEntityImage(
      asset,
      fit: fit,
      isOriginal: false,
      thumbnailSize: highRes ? const ThumbnailSize.square(1000) : const ThumbnailSize.square(250),
      thumbnailFormat: ThumbnailFormat.jpeg,
      loadingBuilder: (context, child, state) {
        if (state == null) return child;
        return Container(color: Colors.white10);
      },
      errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// EDITOR HELPER CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class DrawingPath {
  List<Offset> points;
  Color color;
  double width;
  bool isComplete;

  DrawingPath({
    required this.points,
    required this.color,
    required this.width,
    this.isComplete = false,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;

  DrawingPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    for (var path in paths) {
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < path.points.length - 1; i++) {
        canvas.drawLine(path.points[i], path.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

class StickerItem {
  final String? url;
  final String? text;
  final bool isIcon;
  final bool isText;
  final IconData? icon;
  Offset position;
  double scale;
  double rotation;

  StickerItem({
    this.url,
    this.text,
    this.isIcon = false,
    this.isText = false,
    this.icon,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// POST SHARING ANIMATION OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

class PostSharingOverlay extends StatefulWidget {
  final AssetEntity asset;
  final String type;
  const PostSharingOverlay({super.key, required this.asset, required this.type});

  @override
  State<PostSharingOverlay> createState() => _PostSharingOverlayState();
}

class _PostSharingOverlayState extends State<PostSharingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.1).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.1).chain(CurveTween(curve: Curves.slowMiddle)), weight: 70),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2.0),
    ).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeInExpo)));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Glass Backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          
          // Orbit Animations
          _buildOrbit(200, Colors.blueAccent.withValues(alpha: 0.3), 1.0),
          _buildOrbit(250, Colors.cyanAccent.withValues(alpha: 0.2), -1.2),
          _buildOrbit(300, Colors.purpleAccent.withValues(alpha: 0.1), 0.8),

          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Post Thumbnail Animation
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: FloqGalleryImage(asset: widget.asset),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              
              // Animated Text
              DefaultTextStyle(
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    WavyAnimatedText('SHARING YOUR ${widget.type.toUpperCase()}...'),
                    WavyAnimatedText('OPTIMIZING QUALITY...'),
                    WavyAnimatedText('NOTIFYING FRIENDS...'),
                  ],
                  isRepeatingAnimation: true,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Glow Progress
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Container(
                          width: 200 * _controller.value,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blueAccent, Colors.cyanAccent],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Floating Particles
          ...List.generate(15, (index) => _buildParticle(index)),
        ],
      ),
    );
  }

  Widget _buildOrbit(double radius, Color color, double speedMultiplier) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 6.28 * speedMultiplier,
          child: Container(
            width: radius,
            height: radius,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        return Positioned(
          left: (screenWidth / 2) + (150 * (index.isEven ? 1 : -1) * (index / 15) * _controller.value),
          top: (screenHeight / 2) - (300 * _controller.value * (index / 15)),
          child: Opacity(
            opacity: (1 - _controller.value).clamp(0, 1),
            child: Container(
              width: 3 + (index % 4),
              height: 3 + (index % 4),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
            ),
          ),
        );
      },
    );
  }
}
