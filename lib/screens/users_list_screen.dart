import 'package:chat_app/screens/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search people...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase().trim();
                    });
                  },
                ),
              ),
            ),
            // Users List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('username', isGreaterThanOrEqualTo: _searchQuery)
                    .where('username', isLessThan: _searchQuery + '\uf8ff')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading users.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    );
                  }

                  final users = snapshot.data!.docs.where((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    return _auth.currentUser!.email != data['email'];
                  }).toList();

                  if (users.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(
                      child: Text(
                        'No users found.',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    );
                  }
                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        'No users available.',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return _buildUserListItem(users[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // User List Item
  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                receiverUserEmail: data['email'],
                receiverUserId: data['uid'],
                receiverUserName: data['username'] ?? 'No Name',
                receiverImageUrl: data['imageUrl'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // User Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF1B1B1B),
                  backgroundImage: data['imageUrl'] != null && data['imageUrl'].isNotEmpty
                      ? NetworkImage(data['imageUrl'])
                      : null,
                  child: (data['imageUrl'] == null || data['imageUrl'].isEmpty)
                      ? const Icon(Icons.person, size: 30, color: Color(0xFFD4AF37))
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['username'] ?? 'No Name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['email'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFFD4AF37), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
