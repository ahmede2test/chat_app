// lib/model/user.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String uid;
  final String email;
  final String userName;
  final String? imageUrl;

  const ChatUser({
    required this.uid,
    required this.email,
    required this.userName,
    this.imageUrl,
  });

  // Create a ChatUser object from a Firestore document
  static ChatUser fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatUser(
      uid: doc.id,
      email: data['email'] ?? '',
      userName: data['username'] ?? '',
      imageUrl: data['imageUrl'] as String?,
    );
  }
}