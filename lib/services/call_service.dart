import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/screens/video_call_screen.dart';
import 'package:chat_app/screens/incoming_call_screen.dart';
import 'dart:async';

import '../ model/Call Data Model.dart';



// ******************************************************
// CallService: لإدارة عمليات الاتصال عبر Firestore
// ******************************************************

class CallService {
  // Singleton Pattern لضمان نسخة واحدة
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String callsCollection = 'calls';

  // 1. الانتقال إلى شاشة المكالمة الفعلية
  void navigateToCallScreen(
      BuildContext context,
      Call call,
      {required bool isCaller}) {

    final chatPartnerId = isCaller ? call.receiverId : call.callerId;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          chatRoomId: call.callId,
          chatPartnerId: chatPartnerId,
          isVideoCall: call.isVideoCall,
          isCaller: isCaller,
        ),
      ),
    );
  }

  // 2. بدء مكالمة جديدة (إنشاء وثيقة المكالمة)
  Future<void> makeCall({
    required BuildContext context,
    required String callerId,
    required String callerName,
    // تم إضافة `required` هنا
    required String callerPic,
    required String receiverId,
    required String receiverName,
    // تم إضافة `required` هنا
    required String receiverPic,
    required bool isVideoCall,
  }) async {
    final newCallDoc = _firestore.collection(callsCollection).doc();
    final callId = newCallDoc.id;
    final isVoiceCall = !isVideoCall;

    final newCall = Call(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      // تمرير الصور إلى النموذج
      callerPic: callerPic,
      receiverId: receiverId,
      receiverName: receiverName,
      // تمرير الصور إلى النموذج
      receiverPic: receiverPic,
      isVideoCall: isVideoCall,
      isVoice: isVoiceCall,
      status: 'ringing', // تبدأ كـ "رنين"
      // ملاحظة: قمت بتحويلها إلى Timestamp.now() مباشرة لتجنب خطأ الكاست
      timestamp: Timestamp.now(),
      hasDialled: true,
      chatRoomId: callId,
    );

    try {
      // 2. حفظ وثيقة المكالمة في Firestore
      await newCallDoc.set(newCall.toMap());

      // 3. الانتقال بالمتصل إلى شاشة المكالمة الفعلية
      navigateToCallScreen(context, newCall, isCaller: true);
    } catch (e) {
      print('Error making call: $e');
      // يمكن إضافة SnackBar أو Dialog هنا لإبلاغ المستخدم بالخطأ
    }
  }

  // 3. تحديث حالة المكالمة
  Future<void> updateCallStatus(String callId, String status) async {
    try {
      await _firestore.collection(callsCollection).doc(callId).update({
        'status': status,
        'endTime': status == 'ended' || status == 'rejected' ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      print('Error updating call status: $e');
    }
  }

  // 4. إنهاء المكالمة
  Future<void> endCall(Call call) async {
    await updateCallStatus(call.callId, 'ended');
  }

  // 5. الاستماع للمكالمات الواردة (للمستخدم الحالي)
  StreamSubscription? listenForIncomingCall(
      BuildContext context, String currentUserId) {

    return _firestore
        .collection(callsCollection)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final incomingCall = Call.fromMap(doc.data() as Map<String, dynamic>);

        // منع التنقل إذا كان المستخدم بالفعل على شاشة مكالمة واردة
        if (ModalRoute.of(context)?.settings.name != '/incomingCall') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => IncomingCallScreen(incomingCall: incomingCall),
              settings: const RouteSettings(name: '/incomingCall'),
            ),
          );
        }
      }
    });
  }
}
