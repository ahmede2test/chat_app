import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({Key? key}) : super(key: key);

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();

  // ** دالة التفاعل: للملاحة إلى شاشة الإعدادات **
  void _navigateToSettings() {
    print('Navigating to Settings Screen...');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings page is coming soon!',
            style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD4AF37),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  // ** دالة حذف الحساب بالكامل **
  Future<void> _deleteUserAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // 1. عرض حوار التأكيد
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1B1B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('Delete Account', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return; // إلغاء إذا لم يتم التأكيد

    try {
      // 2. حذف وثيقة المستخدم من Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // 3. محاولة حذف الصورة الشخصية من Firebase Storage (اختياري)
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${user.uid}.jpg');
        await storageRef.delete();
      } catch (e) {
        print("No profile image found or failed to delete image: $e");
        // لا نوقف الحذف إذا فشل حذف الصورة
      }

      // 4. حذف حساب المستخدم من Firebase Auth
      // ملاحظة: قد تتطلب هذه الخطوة إعادة مصادقة إذا كانت الجلسة قديمة
      await user.delete();

      // 5. التوجيه إلى شاشة تسجيل الدخول
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account successfully deleted.', style: GoogleFonts.poppins(color: Colors.black))),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on FirebaseAuthException catch (e) {
      // التعامل مع الأخطاء التي قد تحدث أثناء الحذف
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account. Please re-login and try again. Error: ${e.code}',
                style: GoogleFonts.poppins(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unknown error occurred during deletion.', style: GoogleFonts.poppins(color: Colors.black))),
        );
      }
    }
  }

  // دالة تسجيل الخروج المصححة
  void _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // دالة تحديث الصورة الشخصية
  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      final user = _auth.currentUser;
      if (user == null) return;

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${user.uid}.jpg');

        await storageRef.putFile(imageFile);
        final imageUrl = await storageRef.getDownloadURL();

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({'imageUrl': imageUrl}, SetOptions(merge: true));

        if (mounted) Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: ${e.message}')),
          );
        }
      }
    }
  }

  // دالة تحديث اسم المستخدم
  Future<void> _updateUsername() async {
    final user = _auth.currentUser;
    if (user == null || _usernameController.text.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({'username': _usernameController.text}, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully!')),
      );
    }
  }

  // دالة عرض حوار تحرير الملف الشخصي
  void _showEditProfileDialog(Map<String, dynamic> userData) {
    _usernameController.text = userData['username'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1B1B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
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
                label: Text(
                  'Change Profile Picture',
                  style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
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
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                _updateUsername();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceAround,
        );
      },
    );
  }

  // دالة بناء زر القائمة المشتركة
  Widget _buildProfileButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = const Color(0xFFD4AF37), // لون افتراضي
  }) {
    // تعديل بسيط لإضافة لون الخط الأحمر لزر الحذف
    Color labelColor = (icon == Icons.delete_forever) ? Colors.redAccent : Colors.white;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B1B1B),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 5,
        shadowColor: Colors.black45,
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 20),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: labelColor, // استخدام اللون المخصص
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

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Text(
            'User not logged in. Please sign in.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(currentUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(
              child: Text('Error loading user data.', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final String? imageUrl = userData['imageUrl'] as String?;
        final String userName = userData['username'] ?? 'No Name';
        final String userEmail = _auth.currentUser?.email ?? 'No Email';

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),
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
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userEmail,
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // زر تحرير الملف الشخصي
                      _buildProfileButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit Profile',
                        onPressed: () => _showEditProfileDialog(userData),
                      ),
                      const SizedBox(height: 20),
                      // زر تسجيل الخروج
                      _buildProfileButton(
                        icon: Icons.logout,
                        label: 'Logout',
                        onPressed: _signOut,
                      ),
                      const SizedBox(height: 20),
                      // زر الإعدادات
                      _buildProfileButton(
                        icon: Icons.settings,
                        label: 'Settings',
                        onPressed: _navigateToSettings,
                      ),
                      const SizedBox(height: 20),
                      // زر الخصوصية
                      _buildProfileButton(
                        icon: Icons.lock,
                        label: 'Privacy Policy',
                        onPressed: () => print('Privacy clicked'),
                      ),
                      const SizedBox(height: 20),
                      // ** زر حذف الحساب الجديد والمهم **
                      _buildProfileButton(
                        icon: Icons.delete_forever,
                        label: 'Delete Account',
                        onPressed: _deleteUserAccount, // <--- استدعاء دالة الحذف
                        color: Colors.redAccent, // لون الأيقونة
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
