import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();

  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${_auth.currentUser!.uid}.jpg');

        await storageRef.putFile(imageFile);
        final imageUrl = await storageRef.getDownloadURL();

        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'imageUrl': imageUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      } on FirebaseException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.message}')),
        );
      }
    }
  }

  Future<void> _updateUsername() async {
    if (_usernameController.text.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'username': _usernameController.text});
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> userData) {
    _usernameController.text = userData['username'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1B1B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _updateProfilePicture,
                icon: const Icon(Icons.camera_alt, color: Colors.black),
                label: const Text(
                  'Change Profile Picture',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                _updateUsername();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceAround,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? displayUserId = widget.userId ?? _auth.currentUser?.uid;
    final bool isCurrentUser = displayUserId == _auth.currentUser?.uid;

    if (displayUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Text(
            'User not logged in.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 50),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1549490349-86433532ed6c?ixlib=rb-1.2.1&auto=format&fit=crop&w=1500&q=80',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black54,
                  BlendMode.darken,
                ),
              ),
            ),
            child: AppBar(
              title: Text(
                isCurrentUser ? 'My Profile' : 'Profile',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true, // This is the key change to center the title
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(displayUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading user data.', style: TextStyle(color: Colors.white)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('User data not found.', style: TextStyle(color: Colors.white)),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String? imageUrl = userData['imageUrl'] as String?;
          final String userName = userData['username'] ?? 'No Name';
          final String userEmail = userData['email'] ?? 'No Email';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 180),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                          backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: (imageUrl == null || imageUrl.isEmpty)
                              ? const Icon(Icons.person, size: 80, color: Color(0xFFD4AF37))
                              : null,
                        ),
                        if (isCurrentUser)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
                              ),
                              child: InkWell(
                                onTap: () => _showEditProfileDialog(userData),
                                child: const Icon(Icons.camera_alt, color: Colors.black, size: 24),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B1B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          if (isCurrentUser)
                            _buildProfileButton(
                              icon: Icons.edit_outlined,
                              label: 'Edit Profile',
                              onPressed: () => _showEditProfileDialog(userData),
                            ),
                          if (isCurrentUser) const SizedBox(height: 20),
                          if (isCurrentUser)
                            _buildProfileButton(
                              icon: Icons.logout,
                              label: 'Logout',
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.of(context).pushReplacementNamed('/login');
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B1B1B),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 28),
          const SizedBox(width: 20),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}
