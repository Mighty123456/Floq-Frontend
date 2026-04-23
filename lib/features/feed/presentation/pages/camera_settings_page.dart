import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/users/data/repositories/users_repository_impl.dart';

class CameraSettingsPage extends StatefulWidget {
  final bool initialFrontCamera;
  final bool initialLeftSide;
  final Function(bool, bool) onSave;

  const CameraSettingsPage({
    super.key, 
    required this.initialFrontCamera, 
    required this.initialLeftSide,
    required this.onSave,
  });

  @override
  State<CameraSettingsPage> createState() => _CameraSettingsPageState();
}

class _CameraSettingsPageState extends State<CameraSettingsPage> {
  late bool _alwaysFront;
  late bool _isLeftSide;

  @override
  void initState() {
    super.initState();
    _alwaysFront = widget.initialFrontCamera;
    _isLeftSide = widget.initialLeftSide;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          "Camera settings",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: const SizedBox.shrink(),
        actions: [
          TextButton(
            onPressed: () async {
              // Save to backend
              final navigator = Navigator.of(context);
              final repo = context.read<UsersRepositoryImpl>();
              await repo.updateCameraSettings(
                alwaysStartOnFrontCamera: _alwaysFront, 
                toolbarSide: _isLeftSide ? 'left' : 'right'
              );
              
              widget.onSave(_alwaysFront, _isLeftSide);
              if (mounted) navigator.pop();
            },
            child: Text(
              "Done",
              style: GoogleFonts.poppins(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection([
              _settingTile(Icons.add_circle_outline, "Story"),
              _settingTile(Icons.play_circle_outline, "Reels"),
              _settingTile(Icons.sensors, "Live"),
            ]),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text("Controls", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _buildSection([
              ListTile(
                title: const Text("Always start on front camera", style: TextStyle(color: Colors.white, fontSize: 15)),
                trailing: Switch(
                  value: _alwaysFront,
                  onChanged: (v) => setState(() => _alwaysFront = v),
                  activeThumbColor: Colors.blueAccent,
                ),
              ),
            ]),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 4),
              child: Text("Camera tools", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Choose which side of the screen you want your camera toolbar to be on.",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            _buildSection([
              RadioGroup<bool>(
                groupValue: _isLeftSide,
                onChanged: (v) => setState(() => _isLeftSide = v!),
                child: Column(
                  children: [
                    const RadioListTile<bool>(
                      value: true,
                      title: Text("Left side", style: TextStyle(color: Colors.white, fontSize: 15)),
                      activeColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    const RadioListTile<bool>(
                      value: false,
                      title: Text("Right side", style: TextStyle(color: Colors.white, fontSize: 15)),
                      activeColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.5),
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () {},
    );
  }
}
