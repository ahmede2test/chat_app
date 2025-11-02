import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <== استيراد Firebase Auth
// يجب استيراد CallService هنا
import '../services/call_service.dart';
// يجب استيراد نموذج البيانات المناسب لـ Call
// **ملاحظة: تأكد من صحة مسار الاستيراد هذا في مشروعك**


// ******************************************************
// الثوابت لضبط المظهر (Styling Constants)
// ******************************************************
const Color _kBackgroundColor = Color(0xFF1E1E1E);
const Color _kPrimaryColor = Color(0xFFD4AF37); // لون ذهبي
const Color _kInputFill = Color(0xFF2C2C2C);
const Color _kTextColor = Colors.white;
const Color _kSecondaryTextColor = Color(0xFFAAAAAA);

/// شاشة تفاصيل الدردشة التي تعرض الرسائل وتتيح إرسال المكالمات.
class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatPartnerId;
  final String chatPartnerName;
  // <== 1. إضافة معلومات الصورة للمستخدمين
  final String chatPartnerPic;
  final String currentUserName;
  final String currentUserPic;


  const ChatDetailScreen({
    Key? key,
    required this.chatRoomId,
    required this.chatPartnerId,
    required this.chatPartnerName,
    // <== 2. جعلهم مطلوبين في البناء
    required this.chatPartnerPic,
    required this.currentUserName,
    required this.currentUserPic,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; // <== استخدام Firebase Auth الفعلي
  // <== إضافة نسخة من CallService
  final CallService _callService = CallService();

  // <== 3. استخدام مُعرف المستخدم الحالي الفعلي
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    // الحصول على مُعرف المستخدم الحالي من Auth
    _currentUserId = _firebaseAuth.currentUser?.uid ?? 'unknown_user';
  }


  /// إرسال رسالة نصية إلى Firestore.
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_currentUserId == 'unknown_user') return; // منع إرسال الرسائل إذا لم يتم التحقق من المستخدم

    final message = {
      'senderId': _currentUserId,
      'receiverId': widget.chatPartnerId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add(message);
      _messageController.clear();
    } catch (e) {
      // طباعة الخطأ في حالة فشل الإرسال
      print('Error sending message: $e');
    }
  }

  /// بدء مكالمة (فيديو أو صوت) باستخدام CallService.
  // <== 4. تم تعديل هذه الدالة لتمرير الصور
  void _startCall(BuildContext context, {required bool isVideoCall}) async {
    // نستخدم الـ widget.currentUserName و widget.currentUserPic و widget.chatPartnerPic
    await _callService.makeCall(
      context: context,
      callerId: _currentUserId,
      callerName: widget.currentUserName, // الاسم الممرر
      callerPic: widget.currentUserPic, // <== تم إضافة صورة المتصل
      receiverId: widget.chatPartnerId,
      receiverName: widget.chatPartnerName,
      receiverPic: widget.chatPartnerPic, // <== تم إضافة صورة المستقبل
      isVideoCall: isVideoCall,
    );
    // CallService سيتولى عملية إنشاء المكالمة في Firestore ثم الانتقال
    // بالمتصل إلى شاشة VideoCallScreen
  }

  // ******************************************************
  // دوال بناء واجهة المستخدم (UI Build Methods)
  // ******************************************************

  /// بناء فقاعة الرسالة (Message Bubble)
  Widget _buildMessageBubble(
      QueryDocumentSnapshot<Map<String, dynamic>> message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: isMe ? _kPrimaryColor : _kInputFill,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Text(
            message['text'],
            style: TextStyle(
              color: isMe ? Colors.black87 : _kTextColor,
              // لضمان أن النص يظهر بوضوح فوق الخلفية الذهبية
            ),
          ),
        ),
      ),
    );
  }

  /// بناء قائمة الرسائل في الزمن الحقيقي (StreamBuilder)
  Widget _buildMessageList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // ملاحظة: يجب تعديل الدالة لاستقبال generic type الصحيح
        stream: _firestore
            .collection('chat_rooms')
            .doc(widget.chatRoomId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _kPrimaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'ابدأ محادثتك مع ${widget.chatPartnerName}',
                style: const TextStyle(color: _kSecondaryTextColor),
              ),
            );
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            reverse: true, // لعرض أحدث رسالة في الأسفل
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message['senderId'] == _currentUserId;
              return _buildMessageBubble(message, isMe);
            },
          );
        },
      ),
    );
  }

  /// بناء واجهة إدخال الرسالة (Input Composer)
  Widget _buildInputComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: _kTextColor),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: _kSecondaryTextColor),
                fillColor: _kInputFill,
                filled: true,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide:
                  const BorderSide(color: _kPrimaryColor, width: 2),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: _kPrimaryColor,
            mini: true,
            child: const Icon(Icons.send, color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        title: Text(
          widget.chatPartnerName,
          style:
          const TextStyle(color: _kTextColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          // زر مكالمة الفيديو
          IconButton(
            icon: const Icon(Icons.videocam, color: _kPrimaryColor),
            onPressed: () => _startCall(context, isVideoCall: true),
          ),
          // زر المكالمة الصوتية
          IconButton(
            icon: const Icon(Icons.call, color: _kPrimaryColor),
            onPressed: () => _startCall(context, isVideoCall: false),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildMessageList(),
          _buildInputComposer(),
        ],
      ),
    );
  }
}
