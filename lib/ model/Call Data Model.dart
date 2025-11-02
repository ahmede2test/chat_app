import 'package:cloud_firestore/cloud_firestore.dart';

// ******************************************************
// نموذج Call
// يمثل مستند المكالمة في Firestore لإدارة حالة الاتصال.
// ******************************************************

class Call {
  final String callerId;
  final String callerName;
  final String callerPic;
  final String receiverId;
  final String receiverName;
  final String receiverPic;
  final String callId;
  final String chatRoomId;
  final Timestamp timestamp;

  // خاصية لتحديد ما إذا كان المستخدم هو من أجرى الاتصال
  final bool hasDialled;

  // خصائص نوع الاتصال وحالته
  final bool isVideoCall;
  final bool isVoice;
  final String status; // يمكن أن تكون 'ringing', 'dialling', 'active', 'ended', 'rejected', 'missed'

  Call({
    required this.callerId,
    required this.callerName,
    required this.callerPic,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPic,
    required this.callId,
    required this.chatRoomId,
    required this.timestamp,
    required this.hasDialled,
    required this.isVideoCall,
    required this.isVoice,
    required this.status,
  });

  // ********************************************
  // تحويل نموذج البيانات إلى خريطة Map لحفظها في Firestore
  // ********************************************
  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'callerName': callerName,
      'callerPic': callerPic,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPic': receiverPic,
      'callId': callId,
      'chatRoomId': chatRoomId,
      'timestamp': timestamp,
      'hasDialled': hasDialled,
      'isVideoCall': isVideoCall,
      'isVoice': isVoice,
      'status': status,
    };
  }

  // ********************************************
  // إنشاء نموذج البيانات Call من خريطة Map مُسترجعة من Firestore
  // ********************************************
  factory Call.fromMap(Map<String, dynamic> map) {
    final bool isVideo = map['isVideoCall'] ?? false;

    return Call(
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? 'Unknown Caller',
      callerPic: map['callerPic'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? 'Unknown Receiver',
      receiverPic: map['receiverPic'] ?? '',
      callId: map['callId'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      hasDialled: map['hasDialled'] ?? false,
      isVideoCall: isVideo,
      isVoice: map['isVoice'] ?? !isVideo,
      status: map['status'] ?? 'pending',
    );
  }
}
