import 'package:flutter/material.dart';
import 'chat_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // TODO: Replace with API call to fetch users
  final List<Map<String, dynamic>> users = [];

  void sendRequest(int index) {
    setState(() {
      users[index]['status'] = "sent";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Request sent to ${users[index]['name']}")),
    );
  }

  void openChat(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatWith: users[index]['name']!,
          profileUrl: users[index]['profileUrl']!,
        ),
      ),
    );
  }

  void _showRequestDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Send Request",
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            "Do you want to send a chat request to ${users[index]['name']}?",
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                sendRequest(index);
                Navigator.pop(context);
              },
              child: const Text("Send", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey[900],
        title: const Text(
          "Users",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: user['profileUrl'].isNotEmpty
                    ? NetworkImage(user['profileUrl'])
                    : null,
                backgroundColor: Colors.blueAccent,
                child: user['profileUrl'].isEmpty
                    ? const Icon(Icons.person_outline, color: Colors.white)
                    : null,
              ),
              title: Text(
                user['name'],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              trailing: _buildTrailingButton(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrailingButton(int index) {
    final status = users[index]['status'];
    if (status == "none") {
      return IconButton(
        icon: const Icon(Icons.person_add, color: Colors.green),
        onPressed: () => _showRequestDialog(index),
      );
    } else if (status == "sent") {
      return const Icon(Icons.hourglass_top, color: Colors.orange);
    } else if (status == "accepted") {
      return IconButton(
        icon: const Icon(Icons.chat, color: Colors.blue),
        onPressed: () => openChat(index),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
