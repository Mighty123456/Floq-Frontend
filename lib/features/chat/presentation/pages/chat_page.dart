import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/presentation/pages/user_profile_page.dart';



import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../core/presentation/widgets/bubble_loader.dart';
import '../../../../core/presentation/widgets/bubble_notification.dart';
import '../widgets/premium_sticker_keyboard.dart';


class ChatPage extends StatelessWidget {
  final String chatWith;
  final String profileUrl;
  final String phoneNumber;
  final String userId;

  const ChatPage({
    super.key,
    required this.chatWith,
    this.profileUrl = '',
    this.phoneNumber = '',
    this.userId = '',
  });


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(repository: MockChatRepository()),
      child: _ChatView(
        chatWith: chatWith,
        profileUrl: profileUrl,
        phoneNumber: phoneNumber,
        userId: userId,
      ),

    );
  }
}

class _ChatView extends StatefulWidget {
  final String chatWith;
  final String profileUrl;
  final String phoneNumber;
  final String userId;

  const _ChatView({
    required this.chatWith,
    this.profileUrl = '',
    this.phoneNumber = '',
    this.userId = '',
  });


  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getUserStatus() {
    return isOnline
        ? 'Online'
        : 'Last seen at ${DateFormat('hh:mm a').format(lastSeen)}';
  }

  void _handleSendText() {
    if (_messageController.text.trim().isEmpty) return;
    context.read<ChatBloc>().add(SendTextMessage(_messageController.text));
    _messageController.clear();
  }

  void _openAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _attachItem(Icons.image, 'Gallery Image', _pickImage),
                _attachItem(Icons.camera_alt, 'Camera', _pickCameraImage),
                _attachItem(Icons.insert_drive_file, 'Document', _pickDocument),
                _attachItem(Icons.location_on, 'Location', _pickLocation),
                _attachItem(Icons.person, 'Contact', _pickContact),
                _attachItem(Icons.mic, 'Audio', () => context.read<ChatBloc>().add(SendAudioMessage())),
                _attachItem(Icons.poll, 'Poll', () => context.read<ChatBloc>().add(SendPollMessage())),
                _attachItem(Icons.event, 'Event', () => context.read<ChatBloc>().add(SendEventMessage())),
                _attachItem(Icons.auto_awesome, 'AI Image', () => context.read<ChatBloc>().add(SendAIImageMessage())),
              ],
            ),
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

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null && mounted) context.read<ChatBloc>().add(SendImageMessage(img.path));
  }

  Future<void> _pickCameraImage() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null && mounted) context.read<ChatBloc>().add(SendImageMessage(img.path));
  }

  Future<void> _pickDocument() async {
    final file = await FilePicker.platform.pickFiles();
    if (file != null && mounted) context.read<ChatBloc>().add(SendDocumentMessage(file.files.single.name));
  }

  Future<void> _pickLocation() async {
    await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition();
    if (mounted) context.read<ChatBloc>().add(SendLocationMessage(pos.latitude, pos.longitude));
  }

  Future<void> _pickContact() async {
    if (!await FlutterContacts.requestPermission()) return;
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    if (contacts.isNotEmpty && mounted) {
      context.read<ChatBloc>().add(SendContactMessage(contacts.first.displayName));
    }
  }

  Future<void> _makePhoneCall() async {
    final url = Uri.parse('tel:${widget.phoneNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!mounted) return;
      BubbleNotification.show(
        context,
        "Cannot make phone call",
        type: NotificationType.error,
      );
    }
  }

  Future<void> _makeVideoCall() async {
    BubbleNotification.show(
      context,
      "Video call functionality not implemented",
      type: NotificationType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: _buildAppBar(context, isDark, colorScheme),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.isLoading && state.messages.isEmpty) {
                  return const Center(child: BubbleLoader());
                }
                return _buildMessages(state.messages, isDark, colorScheme);
              },
            ),
          ),
          _buildInput(isDark, colorScheme),
          if (_showEmojiPicker) _buildMediaKeyboard(isDark),
          // Handle safe area bottom padding when picker is NOT shown
          if (!_showEmojiPicker) SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _createCustomSticker() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null && mounted) {
       BubbleNotification.show(
        context,
        "Magically turning image into sticker... ✨",
        type: NotificationType.info,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.read<ChatBloc>().add(SendTextMessage("Sent a custom sticker 🎨"));
        BubbleNotification.show(context, "Sticker added to your collection!", type: NotificationType.success);
      }
    }
  }

  Widget _buildMediaKeyboard(bool isDark) {
    return PremiumStickerKeyboard(
      onStickerSelected: (stkr) => context.read<ChatBloc>().add(SendImageMessage(stkr)),
      onGifSelected: (gif) => context.read<ChatBloc>().add(SendImageMessage(gif)),
      onCreateSticker: _createCustomSticker,
    );
  }



  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark, ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(
                user: UserEntity(
                  id: widget.userId,
                  name: widget.chatWith,
                  profileUrl: widget.profileUrl,
                  relation: UserRelation.accepted,
                ),
              ),
            ),
          );
        },
        child: Row(
          children: [
            Hero(
              tag: 'user_image_${widget.userId}',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: widget.profileUrl.isNotEmpty ? NetworkImage(widget.profileUrl) : null,
                child: widget.profileUrl.isEmpty ? Icon(Icons.person_rounded, color: colorScheme.primary) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatWith,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      if (isOnline)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _getUserStatus(),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOnline ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [

        IconButton(
          icon: Icon(Icons.phone_outlined, color: isDark ? Colors.white70 : Colors.black87),
          onPressed: _makePhoneCall,
        ),
        IconButton(
          icon: Icon(Icons.videocam_outlined, color: isDark ? Colors.white70 : Colors.black87),
          onPressed: _makeVideoCall,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessages(List<Message> messages, bool isDark, ColorScheme colorScheme) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text("Say hi! No messages yet.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final time = DateFormat('hh:mm a').format(msg.timestamp);
        final isMe = msg.senderId == 'me';

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe 
                      ? colorScheme.primary 
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 5),
                    bottomRight: Radius.circular(isMe ? 5 : 20),
                  ),
                  boxShadow: [],

                ),
                child: _buildMessageContent(msg, isMe),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                child: Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageContent(Message msg, bool isMe) {
    final TextStyle textStyle = GoogleFonts.poppins(
      color: isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
      fontSize: 15,
    );

    switch (msg.type) {
      case MessageType.image:
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: msg.content.startsWith('http') 
                ? CachedNetworkImage(
                    imageUrl: msg.content,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
                  )
                : Image.file(File(msg.content), fit: BoxFit.cover),
            ),

            const SizedBox(height: 4),
            if (msg.content.contains('/')) const Text("Image sent", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        );
      case MessageType.document:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_rounded, color: isMe ? Colors.white : Colors.blue),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                msg.content,
                style: textStyle.copyWith(decoration: TextDecoration.underline),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      default:
        return Text(msg.content, style: textStyle);
    }
  }

  Widget _buildInput(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary, size: 28),
            onPressed: _openAttachmentMenu,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      maxLines: 5,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSendText(),
                    ),

                  ),
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[500]),
                    onPressed: () {
                      _focusNode.unfocus();
                      setState(() => _showEmojiPicker = !_showEmojiPicker);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSendText,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
