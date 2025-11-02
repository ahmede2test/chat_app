import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../ model/message.dart';

class ChatService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  // Send a message
  // تم إضافة المُدخل الاختياري الجديد: [repliedToMessageId]
  Future<void> sendMessage(
      String receiverId,
      String message,
      String messageType, {
        String? repliedToMessageId, // <-- المُدخل الجديد للردود
      }) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();

    final newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      isRead: false,
      messageType: messageType,
      repliedToMessageId: repliedToMessageId, // <-- تمرير المُعرف هنا
    );

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // Update the last message in the chat room for quick access
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'lastMessage': messageType == 'image' ? 'Image 🖼️' : message,
      'timestamp': timestamp,
      'members': ids,
    }, SetOptions(merge: true));
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String userId, String otherUserId) async {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final messages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Get chat rooms for the current user
  Stream<QuerySnapshot> getChatRooms(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('members', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // تم تحديث هذه الدالة لتمرير مُعرف الرد أيضاً
  Future<void> sendImage(
      String receiverId,
      File imageFile, {
        String? repliedToMessageId, // <-- المُدخل الجديد للردود
      }) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final Reference ref = _firebaseStorage.ref().child('chat_images/$currentUserId/$fileName');

    final UploadTask uploadTask = ref.putFile(imageFile);
    final TaskSnapshot downloadUrl = await uploadTask;
    final String url = await downloadUrl.ref.getDownloadURL();

    await sendMessage(
      receiverId,
      url,
      'image',
      repliedToMessageId: repliedToMessageId, // <-- تمرير المُعرف إلى sendMessage
    );
  }

  // Delete message function
  Future<void> deleteMessage(String receiverId, String messageId) async {
    try {
      final String currentUserId = _firebaseAuth.currentUser!.uid;
      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      final messageDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').doc(messageId).get();
      final messageData = messageDoc.data();

      if (messageData != null && messageData['messageType'] == 'image') {
        final imageUrl = messageData['message'] as String;
        final storageRef = _firebaseStorage.refFromURL(imageUrl);
        await storageRef.delete();
      }

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print('Error deleting message: $e');
    }
  }
}
