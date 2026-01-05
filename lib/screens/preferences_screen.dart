import 'package:flutter/material.dart';
import '../main.dart';
import 'package:chatapplication/screens/auth/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _notifications = true;
  late bool _darkTheme;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  String _appVersion = '';


  @override
  void initState() {
    super.initState();
    _darkTheme = themeNotifier.value == ThemeMode.dark;
    _loadAppInfo(); // load app version
  }

// Load the actual app version
  void _loadAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

// Launch help/support URL
  void _launchHelp() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final url = Uri.parse('https://yourappwebsite.com/help'); // replace with your URL
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text("Could not open help page")),
      );
    }
  }

  void _editProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: "John Doe");
    final TextEditingController emailController = TextEditingController(text: "johndoe@example.com");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // allows setState inside dialog
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setStateDialog(() {
                        _profileImage = File(pickedFile.path);
                      });
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[700],
                    backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Name",
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                // Here you can update your state or send to server
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Profile updated: ${nameController.text}",
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }

  void _changePasswordDialog() {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Change Password", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Old Password",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPassController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "New Password",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPassController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Confirm New Password",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              if (newPassController.text != confirmPassController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match!")),
                );
              } else {
                // Update password logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password changed successfully!")),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _privacySettingsDialog() {
    bool showOnlineStatus = true;
    bool allowRequests = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Privacy Settings", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: showOnlineStatus,
                onChanged: (val) => setStateDialog(() => showOnlineStatus = val),
                title: const Text("Show Online Status", style: TextStyle(color: Colors.white)),
              ),
              SwitchListTile(
                value: allowRequests,
                onChanged: (val) => setStateDialog(() => allowRequests = val),
                title: const Text("Allow Friend Requests", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Row(
          children: const [
            Icon(
              Icons.settings,
              color: Colors.blueAccent,
            ),
            SizedBox(width: 8),
            Text(
              "Preferences",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Profile",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person_outlined, color: Colors.white),
                  ),
                  title: const Text("John Doe"),
                  subtitle: const Text("johndoe@example.com"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _editProfileDialog,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Account Section

          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Account",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock,color: Colors.white,),
                    label: const Text("Change Password",style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _changePasswordDialog, // opens change password dialog
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shield,color: Colors.white,),
                    label: const Text("Privacy",style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _privacySettingsDialog, // opens privacy dialog
                  ),
                ),
              ],
            ),
          ),


          const SizedBox(height: 16),

          // Notifications Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Notifications",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
                SwitchListTile(
                  value: _notifications,
                  onChanged: (val) {
                    setState(() {
                      _notifications = val;
                    });

                  },
                  title: const Text("Enable Notifications"),
                  secondary: const Icon(Icons.notifications),
                  activeThumbColor: Colors.blueAccent,
                  activeTrackColor: Colors.blueAccent.withValues(alpha: 0.4),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[700],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Appearance Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Appearance",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
                SwitchListTile(
                  value: _darkTheme,
                  onChanged: (val) {
                    setState(() {
                      _darkTheme = val;
                      // Update the global themeNotifier directly
                      themeNotifier.value =
                      val ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                  title: const Text("Dark Theme"),
                  secondary: const Icon(Icons.brightness_6),
                  activeThumbColor: Colors.blueAccent,
                  activeTrackColor: Colors.blueAccent.withValues(alpha: 0.4),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey[700],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // About Section
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "About",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text("App Version"),
                  subtitle: Text(_appVersion.isEmpty ? "Loading..." : _appVersion),
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text("Help & Support"),
                  onTap: _launchHelp, // Opens a webpage
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text("Privacy Policy"),
                  onTap: () async {
                    if (!mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    const url = 'https://yourappwebsite.com/privacy'; // Replace with your URL
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    } else {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Could not open privacy policy")),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logout Section
          _buildCard(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ),

        ],
      ),
    );
  }


  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }
}
