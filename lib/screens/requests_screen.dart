import 'package:flutter/material.dart';

class RequestsScreen extends StatefulWidget {
  final void Function(String name) onRequestAccepted;

  const RequestsScreen({super.key, required this.onRequestAccepted});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  // TODO: Replace with API call to fetch requests
  List<Map<String, dynamic>> requests = [];

  void _acceptRequest(int index) async {
    setState(() {
      requests[index]['loading'] = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final acceptedUser = requests[index]['name'];

    setState(() {
      requests.removeAt(index);
    });

    // Notify parent
    widget.onRequestAccepted(acceptedUser);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Accepted request from $acceptedUser")),
    );
  }

  void _declineRequest(int index) {
    final declinedUser = requests[index]['name'];

    setState(() {
      requests.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Declined request from $declinedUser")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dark theme colors only
    const backgroundColor = Color(0xFF121212);
    const cardColor = Color(0xFF1E1E1E);
    const titleColor = Colors.white;
    const subtitleColor = Colors.white70;


    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: requests.isEmpty
          ? const Center(
        child: Text(
          "No pending requests",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final user = requests[index];
          final isLoading = user['loading'] as bool;

          return Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blueAccent,
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                ),
              ),
              title: Text(
                user['name'],
                style: const TextStyle(color: titleColor),
              ),
              subtitle: const Text(
                "wants to connect with you",
                style: TextStyle(color: subtitleColor),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  )
                      : IconButton(
                    icon: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    onPressed: () => _acceptRequest(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _declineRequest(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
