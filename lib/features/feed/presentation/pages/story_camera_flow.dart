import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/users/data/repositories/users_repository_impl.dart';
import 'camera_settings_page.dart';

class StoryCameraFlow extends StatefulWidget {
  const StoryCameraFlow({super.key});

  @override
  State<StoryCameraFlow> createState() => _StoryCameraFlowState();
}

class _StoryCameraFlowState extends State<StoryCameraFlow> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isReady = false;
  AssetEntity? _lastGalleryImage;
  
  // Settings state
  bool _alwaysFront = false;
  bool _isLeftSide = true;
  String _selectedMode = "STORY";
  FlashMode _flashMode = FlashMode.off;

  void _toggleFlash() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.always;
      } else if (_flashMode == FlashMode.always) {
        _flashMode = FlashMode.auto;
      } else {
        _flashMode = FlashMode.off;
      }
      _controller!.setFlashMode(_flashMode);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettingsAndSetup();
    _loadLastGalleryImage();
  }

  Future<void> _loadSettingsAndSetup() async {
    // Load from backend
    final repo = context.read<UsersRepositoryImpl>();
    final me = await repo.getMe();
    if (me != null) {
      setState(() {
        _alwaysFront = me.cameraSettings['alwaysStartOnFrontCamera'] ?? false;
        _isLeftSide = me.cameraSettings['toolbarSide'] == 'left';
      });
    }

    _setupCamera();
  }

  Future<void> _loadLastGalleryImage() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps == PermissionState.authorized || ps == PermissionState.limited) {
        List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true);
        if (albums.isNotEmpty) {
          List<AssetEntity> assets = await albums[0].getAssetListRange(start: 0, end: 1);
          if (mounted && assets.isNotEmpty) {
            setState(() => _lastGalleryImage = assets.first);
          }
        }
      }
    } catch (e) {
      debugPrint("Gallery Error: $e");
    }
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        if (_alwaysFront) {
          final front = _cameras!.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
          if (front != -1) _selectedCameraIndex = front;
        }
        await _initCamera(_cameras![_selectedCameraIndex]);
      } else {
        debugPrint("No cameras found");
      }
    } catch (e) {
      debugPrint("Setup Camera Error: $e");
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      debugPrint("Camera Initialization Error: $e");
      if (mounted) {
        setState(() => _isReady = false);
      }
    }
  }

  void _toggleCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    _initCamera(_cameras![_selectedCameraIndex]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          _isReady && _controller != null && _controller!.value.isInitialized
            ? Center(
                child: CameraPreview(_controller!),
              )
            : Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_outlined, color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      Text("Camera not available", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Check permissions in settings", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _setupCamera,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                        child: Text("Retry", style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),

          // 2. Top Bar
          _buildTopBar(),

          // 3. Side Tools
          _buildSideTools(),

          // 4. Bottom Controls
          _buildBottomControls(),

          // 5. Mode Selector
          _buildModeSelector(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16, right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 28)),
          IconButton(
            onPressed: _toggleFlash, 
            icon: Icon(
              _flashMode == FlashMode.off 
                ? Icons.flash_off 
                : (_flashMode == FlashMode.always ? Icons.flash_on : Icons.flash_auto), 
              color: Colors.white, size: 24
            )
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CameraSettingsPage(
                initialFrontCamera: _alwaysFront,
                initialLeftSide: _isLeftSide,
                onSave: (front, left) {
                  setState(() {
                    _alwaysFront = front;
                    _isLeftSide = left;
                  });
                },
              )));
            }, 
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24)
          ),
        ],
      ),
    );
  }

  Widget _buildSideTools() {
    final bool isReel = _selectedMode == "REEL";
    
    return Positioned(
      left: _isLeftSide ? 16 : null,
      right: _isLeftSide ? null : 16,
      top: MediaQuery.of(context).size.height * (isReel ? 0.2 : 0.3),
      child: Column(
        children: isReel ? [
          _sideToolItem(Icons.music_note, "Audio"),
          const SizedBox(height: 20),
          _sideToolItem(Icons.auto_awesome, "Effects"),
          const SizedBox(height: 20),
          _sideToolItem(Icons.more_time, "Length"),
          const SizedBox(height: 20),
          _sideToolItem(Icons.speed, "Speed"),
          const SizedBox(height: 20),
          _sideToolItem(Icons.grid_view_rounded, "Layout"),
          const SizedBox(height: 20),
          _sideToolItem(Icons.timer_outlined, "Timer"),
        ] : [
          _sideToolItem(Icons.text_fields, "Create"),
          const SizedBox(height: 24),
          _sideToolItem(Icons.all_inclusive, "Boomerang"),
          const SizedBox(height: 24),
          _sideToolItem(Icons.auto_awesome_outlined, "AI Images"),
          const SizedBox(height: 24),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ],
      ),
    );
  }

  Widget _sideToolItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 100,
      left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery Icon
          GestureDetector(
            onTap: () {
               // In a real app, this would open the gallery step of the creation flow
            },
            child: Container(
              width: 45, height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _lastGalleryImage != null 
                  ? FloqGalleryImage(asset: _lastGalleryImage!)
                  : Container(color: Colors.grey),
              ),
            ),
          ),

          // Filter Bubbles (Left)
          _filterBubble("assets/1.jpg"),
          _filterBubble("assets/2.jpg"),

          // Capture Button
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
              ),
              child: Center(
                child: Container(
                  width: 65, height: 65,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),

          // Filter Bubbles (Right)
          _filterBubble("assets/3.jpg"),

          // Camera Flip
          IconButton(
            onPressed: _toggleCamera,
            icon: const Icon(Icons.cached, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _filterBubble(String imagePath) {
    return Container(
      width: 45, height: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.white10)),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Positioned(
      bottom: 30,
      left: 0, right: 0,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              const SizedBox(width: 150), // Spacer for centering
              _modeItem("POST"),
              _modeItem("STORY"),
              _modeItem("REEL"),
              _modeItem("LIVE"),
              const SizedBox(width: 150),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeItem(String label) {
    final bool isActive = _selectedMode == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMode = label;
          });
        },
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    try {
      final XFile file = await _controller!.takePicture();
      // Navigate to editing step
      if (mounted) {
         // This would normally go to the Preview/Edit step implemented in PostCreationFlow
         // For now we show a notification
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Captured Story: ${file.path}")));
      }
    } catch (e) {
      debugPrint("Capture Error: $e");
    }
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
