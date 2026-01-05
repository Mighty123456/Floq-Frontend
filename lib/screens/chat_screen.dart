import 'dart:io';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final String chatWith;
  final String profileUrl;
  final String phoneNumber; // optional for call

  const ChatScreen({
    super.key,
    required this.chatWith,
    this.profileUrl = '',
    this.phoneNumber = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];

  bool _showEmojiPicker = false;
  bool isOnline = true;
  DateTime lastSeen = DateTime.now().subtract(const Duration(minutes: 5));

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) setState(() => _showEmojiPicker = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------- STATUS ----------------
  String _getUserStatus() {
    return isOnline
        ? 'Online'
        : 'Last seen at ${DateFormat('hh:mm a').format(lastSeen)}';
  }

  // ---------------- SEND TEXT ----------------
  void _sendText() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'type': 'text',
        'content': _controller.text.trim(),
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
      _controller.clear();
    });
  }

  // ---------------- OPEN ATTACHMENT MENU ----------------
  void _openAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _attachItem(Icons.image, 'Gallery Image', _sendImage),
              _attachItem(Icons.camera_alt, 'Camera', _sendCameraImage),
              _attachItem(Icons.insert_drive_file, 'Document', _sendDocument),
              _attachItem(Icons.location_on, 'Location', _sendLocation),
              _attachItem(Icons.person, 'Contact', _sendContact),
              _attachItem(Icons.mic, 'Audio', _sendAudio),
              _attachItem(Icons.poll, 'Poll', _sendPoll),
              _attachItem(Icons.event, 'Event', _sendEvent),
              _attachItem(Icons.auto_awesome, 'AI Image', _sendAIImage),
            ],
          ),
        );
      },
    );
  }

  Widget _attachItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blueGrey,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // ---------------- SEND MEDIA ----------------
  Future<void> _sendImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    setState(() {
      _messages.add({
        'type': 'image',
        'content': img.path,
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
    });
  }

  Future<void> _sendCameraImage() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img == null) return;

    setState(() {
      _messages.add({
        'type': 'image',
        'content': img.path,
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
    });
  }

  Future<void> _sendDocument() async {
    final file = await FilePicker.platform.pickFiles();
    if (file == null) return;

    setState(() {
      _messages.add({
        'type': 'document',
        'content': file.files.single.name,
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
    });
  }

  Future<void> _sendLocation() async {
    await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _messages.add({
        'type': 'location',
        'content': '${pos.latitude}, ${pos.longitude}',
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
    });
  }

  Future<void> _sendContact() async {
    if (!await FlutterContacts.requestPermission()) return;
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (contacts.isEmpty) return;

    final contact = contacts.first;
    setState(() {
      _messages.add({
        'type': 'contact',
        'content': contact.displayName,
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
    });
  }

  void _sendAudio() {
    setState(() {
      _messages.add({
        'type': 'audio',
        'content': 'Audio message',
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
    });
  }

  void _sendPoll() {
    setState(() {
      _messages.add({
        'type': 'poll',
        'content': 'Which feature do you like most?',
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
    });
  }

  void _sendEvent() {
    setState(() {
      _messages.add({
        'type': 'event',
        'content': 'Meeting Tomorrow at 10 AM',
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
    });
  }

  void _sendAIImage() {
    setState(() {
      _messages.add({
        'type': 'ai',
        'content': 'AI Generated Image',
        'sender': 'me',
        'time': DateTime.now(),
        'status': 'sent',
      });
    });
  }

  // ---------------- CALL FUNCTIONS ----------------
  Future<void> _makePhoneCall() async {
    final url = Uri.parse('tel:${widget.phoneNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot make phone call")));
    }
  }

  Future<void> _makeVideoCall() async {
    // For demonstration, we just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Video call functionality not implemented")),
    );
    // In real apps, integrate with a service like Agora, WebRTC, or Jitsi
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessages()),
            _buildInput(),
            if (_showEmojiPicker) _buildEmojiPicker(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blueGrey[900],
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey,
            child: const Icon(Icons.person),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.chatWith),
              Text(_getUserStatus(), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: _makePhoneCall,
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: _makeVideoCall,
        ),
      ],
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[_messages.length - 1 - index];
        final time = DateFormat('hh:mm a').format(msg['time']);
        return Align(
          alignment: msg['sender'] == 'me' ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: msg['sender'] == 'me' ? const Color(0xFF37474F) : Colors.grey[800],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMessageContent(msg),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageContent(Map msg) {
    switch (msg['type']) {
      case 'image':
        return Image.file(File(msg['content']), height: 150);
      case 'document':
        return Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.white),
            const SizedBox(width: 6),
            Text(msg['content'], style: const TextStyle(color: Colors.white)),
          ],
        );
      default:
        return Text(msg['content'], style: const TextStyle(color: Colors.white, fontSize: 16));
    }
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[900],
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.attach_file, color: Colors.grey), onPressed: _openAttachmentMenu),
          IconButton(
              icon: const Icon(Icons.emoji_emotions, color: Colors.grey),
              onPressed: () {
                _focusNode.unfocus();
                setState(() => _showEmojiPicker = !_showEmojiPicker);
              }),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type a message',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _sendText),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (c, e) => _controller.text += e.emoji,
        config: const Config(),
      ),
    );
  }
}
