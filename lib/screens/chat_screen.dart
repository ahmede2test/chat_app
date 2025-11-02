import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chat_app/widgets/chat_bubble.dart';
import 'package:chat_app/screens/image_view_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../ model/message.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
// <== 1. استيراد خدمة المكالمات
import '../services/call_service.dart';

import 'profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserId;
  final String receiverUserName;
  final String? receiverImageUrl;

  const ChatScreen({
    Key? key,
    required this.receiverUserEmail,
    required this.receiverUserId,
    required this.receiverUserName,
    this.receiverImageUrl,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  // <== 2. تعريف خدمة المكالمات
  final CallService _callService = CallService();

  // متغيرات الحالة الجديدة لتخزين بيانات الرد بشكل منظم
  String? _replyToMessageId;
  String? _replyToMessageContent;
  String? _replyToMessageType;

  // <== 3. تخزين بيانات المستخدم الحالي (تم إضافة الصورة)
  String _currentUserName = 'You';
  String? _currentUserImageUrl; // متغير جديد للصورة

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsRead(
      _firebaseAuth.currentUser!.uid,
      widget.receiverUserId,
    );
    // <== جلب بيانات المستخدم الحالي عند التهيئة
    _fetchCurrentUserData();
  }

  void _fetchCurrentUserData() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      final userData = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      setState(() {
        _currentUserName = userData.data()?['username'] ?? 'You';
        // جلب الصورة
        _currentUserImageUrl = userData.data()?['imageUrl'] as String?;
      });
    }
  }

  // <== 4. دالة بدء المكالمة (تم التعديل)
  void _startCall({required bool isVideoCall}) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return;

    // التأكد من وجود صورة للمتصل، إذا لم تكن موجودة نستخدم رابط فارغ أو صورة افتراضية
    final callerPic = _currentUserImageUrl ?? '';
    // التأكد من وجود صورة للمستقبل، إذا لم تكن موجودة نستخدم رابط فارغ أو صورة افتراضية
    final receiverPic = widget.receiverImageUrl ?? '';

    await _callService.makeCall(
      context: context,
      callerId: currentUser.uid,
      callerName: _currentUserName,
      callerPic: callerPic, // <== تم إضافة المعلمة المطلوبة
      receiverId: widget.receiverUserId,
      receiverName: widget.receiverUserName,
      receiverPic: receiverPic, // <== تم إضافة المعلمة المطلوبة
      isVideoCall: isVideoCall,
    );
  }

  // تم تحديث هذه الدالة لتمرير repliedToMessageId
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String messageContent = _messageController.text;
      String messageType = 'text';

      await _chatService.sendMessage(
        widget.receiverUserId,
        messageContent,
        messageType,
        repliedToMessageId: _replyToMessageId, // <-- تمرير مُعرف الرد
      );

      _messageController.clear();
      // مسح حالة الرد بعد الإرسال
      setState(() {
        _replyToMessageId = null;
        _replyToMessageContent = null;
        _replyToMessageType = null;
      });
      _scrollToBottom();
    }
  }

  // تم تحديث هذه الدالة لتمرير repliedToMessageId
  void _sendImage({required ImageSource source}) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final File file = File(image.path);

      // يمكنك إضافة مؤشر تحميل هنا قبل الرفع

      await _chatService.sendImage(
        widget.receiverUserId,
        file,
        repliedToMessageId: _replyToMessageId, // <-- تمرير مُعرف الرد
      );

      // مسح حالة الرد بعد الإرسال
      setState(() {
        _replyToMessageId = null;
        _replyToMessageContent = null;
        _replyToMessageType = null;
      });
      _scrollToBottom();
    }
  }

  void _deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(widget.receiverUserId, messageId);
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  void _navigateToReceiverProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.receiverUserId),
      ),
    );
  }

  // دالة مساعدة للحصول على Chat Room ID، وهي ضرورية لـ ChatBubble
  String _getChatRoomId(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    return ids.join('_');
  }

  // دالة التمرير إلى أسفل القائمة
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ******************************************************
  // ** تم التعديل لحل خطأ 'id' can't be used as a setter **
  // ******************************************************
  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      // هنا يجب أن يكون المستخدم الحالي هو الأول والطرف الآخر هو الثاني
      stream: _chatService.getMessages(_firebaseAuth.currentUser!.uid, widget.receiverUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error', style: TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        // حساب Chat Room ID مرة واحدة
        final String currentChatRoomId = _getChatRoomId(_firebaseAuth.currentUser!.uid, widget.receiverUserId);

        // 1. جلب جميع الرسائل وتخزينها في خريطة (Map) للوصول السريع
        final List<Message> allMessages = snapshot.data!.docs.map((document) {
          // استخدام Message.fromSnapshot لتعيين ID و ChatRoomId كجزء من عملية الإنشاء
          // هذا يحافظ على أن الحقول Final تُعيَّن مرة واحدة فقط.
          return Message.fromSnapshot(document, chatRoomId: currentChatRoomId);
        }).toList();

        // 2. إنشاء خريطة الوصول السريع
        // نستخدم (!) للتأكيد على أن message.id ليس null لأنه تم تعيينه في fromSnapshot
        final Map<String, Message> messageMap = { for (var msg in allMessages) msg.id!: msg };

        return ListView.builder(
          controller: _scrollController,
          itemCount: allMessages.length,
          reverse: true, // الأحدث في الأسفل
          itemBuilder: (context, index) {
            final message = allMessages[index];
            final isMe = (message.senderId == _firebaseAuth.currentUser!.uid);

            // استرداد الرسالة المقتبس منها من الخريطة
            Message? repliedToMessage;
            // نستخدم (!) للتأكيد على أن message.repliedToMessageId ليس null عند التحقق
            if (message.repliedToMessageId != null && messageMap.containsKey(message.repliedToMessageId!)) {
              repliedToMessage = messageMap[message.repliedToMessageId!];
            }

            return _buildMessageItem(message, repliedToMessage);
          },
        );
      },
    );
  }

  // تم تحديث هذه الدالة لتمرير الرسالة المقتبس منها (repliedToMessage)
  Widget _buildMessageItem(Message message, Message? repliedToMessage) {
    final isMe = (message.senderId == _firebaseAuth.currentUser!.uid);
    // message.id أصبح متاحاً مباشرة بعد استخدام Message.fromSnapshot
    final String docId = message.id!;

    return InkWell(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF2C2C2C),
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.reply, color: Color(0xFFD4AF37)),
                    title: const Text('Reply', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        _replyToMessageId = docId;
                        // تحديد محتوى الرد المعروض في شريط الإدخال
                        _replyToMessageContent = message.messageType == 'image'
                            ? 'Image 🖼️'
                            : (message.message.length > 30 ? message.message.substring(0, 30) + '...' : message.message);
                        _replyToMessageType = message.messageType;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  if (isMe)
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Delete', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        _deleteMessage(docId);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
      child: ChatBubble(
        message: message,
        isMe: isMe,
        repliedToMessage: repliedToMessage, // <-- تمرير الرسالة المقتبس منها هنا
        receiverUserName: widget.receiverUserName,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171923),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: GestureDetector(
          onTap: _navigateToReceiverProfile,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.receiverImageUrl != null && widget.receiverImageUrl!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewScreen(imageUrl: widget.receiverImageUrl!),
                      ),
                    );
                  }
                },
                child: (widget.receiverImageUrl != null && widget.receiverImageUrl!.isNotEmpty)
                    ? CircleAvatar(
                  backgroundImage: NetworkImage(widget.receiverImageUrl!),
                  radius: 20,
                )
                    : const CircleAvatar(
                  child: Icon(Icons.person, color: Colors.white),
                  radius: 20,
                ),
              ),
              const SizedBox(width: 10),
              // ******************************************************
              // ** حل مشكلة App Bar "يزيد" باستخدام Expanded **
              // ******************************************************
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverUserId).snapshots(),
                  builder: (context, snapshot) {
                    // ... (باقي منطق عرض الحالة)
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final receiverData = snapshot.data!.data() as Map<String, dynamic>;
                      final bool isOnline = receiverData['isOnline'] ?? false;
                      final Timestamp? lastSeenTimestamp = receiverData['lastSeen'] as Timestamp?;

                      String statusText;
                      Color statusColor;

                      if (isOnline) {
                        statusText = 'Active Now';
                        statusColor = Colors.greenAccent;
                      } else if (lastSeenTimestamp != null) {
                        final lastSeen = lastSeenTimestamp.toDate();
                        final now = DateTime.now();
                        final difference = now.difference(lastSeen);

                        if (difference.inDays > 0) {
                          statusText = 'Last seen ${difference.inDays} days ago';
                        } else if (difference.inHours > 0) {
                          statusText = 'Last seen ${difference.inHours} hours ago';
                        } else if (difference.inMinutes > 0) {
                          statusText = 'Last seen ${difference.inMinutes} minutes ago';
                        } else {
                          statusText = 'Last seen just now';
                        }
                        statusColor = Colors.grey;
                      } else {
                        statusText = 'Offline';
                        statusColor = Colors.grey;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.receiverUserName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              overflow: TextOverflow.ellipsis, // تأكد من عدم تجاوز الاسم الطويل
                            ),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    }
                    return Text(
                      widget.receiverUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          // <== 5. ربط زر المكالمة الصوتية
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFFD4AF37)),
            onPressed: () => _startCall(isVideoCall: false),
          ),
          // <== 6. ربط زر مكالمة الفيديو
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFFD4AF37)),
            onPressed: () => _startCall(isVideoCall: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          // شريط الرد
          if (_replyToMessageId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to: "${_replyToMessageContent}"',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyToMessageId = null;
                        _replyToMessageContent = null;
                        _replyToMessageType = null;
                      });
                    },
                    child: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            ),
          // حقل الإدخال
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Row(
              children: [
                // زر الكاميرا والمعرض
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF2C2C2C),
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt, color: Colors.white),
                            title: const Text('Camera', style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.pop(context);
                              _sendImage(source: ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo, color: Colors.white),
                            title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.pop(context);
                              _sendImage(source: ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onTap: _scrollToBottom,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFFD4AF37),
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      // تم إزالة أزرار الكاميرا/المعرض من الـ suffixIcon ونقلها إلى زر الـ +
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
