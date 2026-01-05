import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  // TODO: Replace with API call to fetch users
  final List<Map<String, dynamic>> users = [];

  // TODO: Replace with API call to fetch groups
  final List<Map<String, dynamic>> groups = [];

  void _openChat(String chatName, {bool isGroup = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatWith: chatName,
          // You could pass a flag for group chats if needed
          // e.g., isGroup: isGroup
        ),
      ),
    );
  }

  void _createNewGroup() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController searchController = TextEditingController();
    String groupName = '';
    List<Map<String, dynamic>> selectedMembers = [];

    // Initially the creator is admin (you)
    const String currentUser = "You"; // replace with logged-in username

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter friends based on search input
            final filteredUsers = users
                .where((u) => u['name']
                .toString()
                .toLowerCase()
                .contains(searchController.text.toLowerCase()))
                .toList();

            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text("Create New Group"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Group name input
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: "Enter group name",
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        groupName = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Search for friends
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: "Search friends or enter new member",
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Select Members",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: filteredUsers.map((user) {
                          final isSelected = selectedMembers
                              .any((member) => member['name'] == user['name']);
                          return CheckboxListTile(
                            title: Text(user['name'],
                                style: const TextStyle(color: Colors.white)),
                            value: isSelected,
                            activeColor: Colors.blue,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  selectedMembers.add({
                                    "name": user['name'],
                                    "isAdmin": false,
                                  });
                                } else {
                                  selectedMembers.removeWhere(
                                          (member) => member['name'] == user['name']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Add new member if not friend
                    ElevatedButton(
                      onPressed: () {
                        final newName = searchController.text.trim();
                        if (newName.isNotEmpty &&
                            !selectedMembers.any(
                                    (member) => member['name'] == newName)) {
                          setState(() {
                            selectedMembers.add({
                              "name": newName,
                              "isAdmin": false,
                            });
                          });
                          searchController.clear();
                        }
                      },
                      child: const Text("Add New Member",style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (groupName.isNotEmpty) {
                      setState(() {
                        // Add current user as admin
                        selectedMembers.insert(
                          0,
                          {"name": currentUser, "isAdmin": true},
                        );
                        groups.add({
                          "name": groupName,
                          "members": selectedMembers,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Create",style: TextStyle(color: Colors.white),),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",style: TextStyle(color: Colors.white),),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _editGroupMembers(int groupIndex) {
    final group = groups[groupIndex];

    // Safely convert all members to Map<String, dynamic>
    List<Map<String, dynamic>> members = [];
    if (group['members'] != null) {
      members = (group['members'] as List<dynamic>).map((member) {
        if (member is String) {
          return {"name": member, "isAdmin": false};
        } else if (member is Map) {
          return Map<String, dynamic>.from(member);
        } else {
          // fallback for unexpected type
          return {"name": member.toString(), "isAdmin": false};
        }
      }).toList();
    }

    final List<String> allUsers = users.map((u) => u['name'] as String).toList();
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter friends based on search text
            final filteredUsers = allUsers
                .where((u) =>
                u.toLowerCase().contains(searchController.text.toLowerCase()))
                .toList();

            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text("Edit Members: ${group['name']}"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: "Search friends or add new member",
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // Scrollable list of friends
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: filteredUsers.map((userName) {
                          final isSelected = members
                              .any((member) => member['name'] == userName);
                          return CheckboxListTile(
                            title: Text(userName,
                                style: const TextStyle(color: Colors.white)),
                            value: isSelected,
                            activeColor: Colors.blue,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  members.add({"name": userName, "isAdmin": false});
                                } else {
                                  members.removeWhere(
                                          (member) => member['name'] == userName);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Add new member if not a friend
                    ElevatedButton(
                      onPressed: () {
                        final newName = searchController.text.trim();
                        if (newName.isNotEmpty &&
                            !members.any((m) => m['name'] == newName)) {
                          setState(() {
                            members.add({"name": newName, "isAdmin": false});
                          });
                          searchController.clear();
                        }
                      },
                      child: const Text("Add New Member",style: TextStyle(color: Colors.white),),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      // Save updated members to the group
                      groups[groupIndex]['members'] = members;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Save",style: TextStyle(color: Colors.white),),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",style: TextStyle(color: Colors.white),),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Users & Groups tabs
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.blueGrey[900],
          title: const Text("Chats",style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold,color: Colors.white),),
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            labelStyle: TextStyle(color: Colors.blueAccent),
            tabs: [
              Tab(text: "Users",),
              Tab(text: "Groups"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _createNewGroup,
              tooltip: "Create Group",
            )
          ],
        ),
        body: TabBarView(
          children: [
            // ---------------- Users List ----------------
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person_outline, color: Colors.white),
                        ),
                        if (user['online'] == true)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[850]!,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(user['name'],
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text("Last message preview...",
                        style: TextStyle(color: Colors.grey[400])),
                    onTap: () => _openChat(user['name']),
                  ),
                );
              },
            ),

            // ---------------- Groups List ----------------
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child:ListTile(
                    leading: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.groups_outlined, color: Colors.white),
                    ),
                    title: Text(group['name'],
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                        group['members'] != null && group['members'] is List
                            ? "Members: ${(group['members'] as List).map((m) => m is Map ? m['name'] : m.toString()).join(', ')}"
                            : "No members",
                        style: TextStyle(color: Colors.grey[400])),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _editGroupMembers(index),
                      tooltip: "Edit Members",
                    ),
                    onTap: () => _openChat(group['name'], isGroup: true),
                  ),

                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
