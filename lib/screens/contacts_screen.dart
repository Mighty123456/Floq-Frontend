import 'package:flutter/material.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 15,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person_outline, color: Colors.white),
              ),
              title: Text(
                "Contact ${index + 1}",
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "Status message...",
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          );
        },
      ),
    );
  }
}

