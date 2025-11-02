import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String? id;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final bool isRead;
  final String messageType;
  final String? repliedToMessageId;
  final String? chatRoomId; // حقل معرف غرفة الدردشة

  Message({
    this.id,
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.messageType,
    this.repliedToMessageId,
    this.chatRoomId, // تم التأكد من وجوده في الباني
  });

  // دالة تحويل الكائن إلى Map لإرساله إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'messageType': messageType,
      'repliedToMessageId': repliedToMessageId,
    };
  }

  // دالة مصنع لتحويل Map إلى كائن Message
  factory Message.fromMap(Map<String, dynamic> map, {String? docId, String? chatRoomId}) {
    // التحقق من وجود الحقول الأساسية لضمان عدم حدوث خطأ
    if (map['senderId'] == null ||
        map['senderEmail'] == null ||
        map['receiverId'] == null ||
        map['message'] == null ||
        map['timestamp'] == null ||
        map['isRead'] == null ||
        map['messageType'] == null) {
      throw const FormatException("Missing required fields in Message data.");
    }

    return Message(
      id: docId,
      senderId: map['senderId'] as String,
      senderEmail: map['senderEmail'] as String,
      receiverId: map['receiverId'] as String,
      message: map['message'] as String,
      // يجب التعامل مع Timestamp بحذر
      timestamp: map['timestamp'] as Timestamp,
      isRead: map['isRead'] as bool,
      messageType: map['messageType'] as String,
      repliedToMessageId: map['repliedToMessageId'] as String?,
      chatRoomId: chatRoomId, // تعيين معرف الغرفة من الباراميتر الإضافي
    );
  }

  // دالة مصنع لتحويل DocumentSnapshot مباشرة وتعيين ID و ChatRoomId
  factory Message.fromSnapshot(DocumentSnapshot doc, {required String chatRoomId}) {
    final data = doc.data();
    if (data == null || data is! Map<String, dynamic>) {
      throw Exception("Document data is null or not a valid Map.");
    }
    // تمرير chatRoomId إلى fromMap
    return Message.fromMap(data, docId: doc.id, chatRoomId: chatRoomId);
  }
}
