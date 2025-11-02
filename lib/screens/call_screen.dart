import 'package:flutter/material.dart';

import 'package:chat_app/services/call_service.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:provider/provider.dart';

import '../ model/Call Data Model.dart';

class CallScreen extends StatefulWidget {
  final Call call;
  final bool isCaller;

  const CallScreen({
    Key? key,
    required this.call,
    required this.isCaller,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  // ************* حالة شاشة المكالمة *************
  bool isMuted = false;
  bool isCallActive = false; // ستتغير إلى true بعد الرد على المكالمة
  String callStatus = 'Awaiting Answer...';
  // ************* الرسوم المتحركة *************
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;


  @override
  void initState() {
    super.initState();
    // إعداد حركة النبض (Pulse Animation)
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // محاكاة الاتصال/الرد بعد 3 ثوانٍ
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isCallActive = true;
          callStatus = 'Call Active';
          _pulseController.stop(); // إيقاف النبض بعد الاتصال
        });
      }
    });

  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // إنهاء المكالمة
  void _endCall() async {
    final callService = CallService(); // استخدام النسخة العالمية
    await callService.endCall(widget.call);
    if (mounted) {
      // إغلاق شاشة المكالمة
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // تحديد اسم الطرف الآخر
    // ملاحظة: يجب أن تكون AuthService متاحة عبر Provider في الشجرة
    // إذا لم تكن متاحة، ستحتاج إلى إزالتها أو إضافتها إلى شجرة Widgets
    final authService = Provider.of<AuthService>(context, listen: false);
    final opponentName = widget.isCaller ? widget.call.receiverName : widget.call.callerName;
    // يمكن استخدام opponentId للـ WebRTC لاحقاً
    final opponentId = widget.isCaller ? widget.call.receiverId : widget.call.callerId;


    return Scaffold(
      backgroundColor: const Color(0xFF161616), // خلفية أغمق للفخامة
      body: Stack(
        children: [
          // 1. خلفية متدرجة
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF161616), Color(0xFF252525)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 2. المحتوى الرئيسي
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // معلومات المتصل/المستقبل
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      // دائرة النبض الجمالية
                      ScaleTransition(
                        scale: isCallActive ? const AlwaysStoppedAnimation(1.0) : _pulseAnimation,
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: theme.colorScheme.primary.withOpacity(isCallActive ? 0.0 : 0.2),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundColor: theme.scaffoldBackgroundColor,
                            child: Icon(
                              // *** التصحيح هنا: استخدام isVideoCall وتعيين الرمز المناسب ***
                              widget.call.isVideoCall ? Icons.videocam_outlined : Icons.person, // <== تم الإصلاح
                              size: 70,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // اسم الطرف الآخر
                      Text(
                        opponentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // حالة المكالمة
                      Text(
                        callStatus,
                        style: TextStyle(
                          color: isCallActive ? Colors.greenAccent : Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),

                  // أزرار التحكم
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // زر كتم الصوت
                      _buildControlButton(
                        icon: isMuted ? Icons.mic_off : Icons.mic,
                        label: isMuted ? 'Unmute' : 'Mute',
                        color: isMuted ? theme.colorScheme.primary : Colors.white24,
                        onPressed: () {
                          setState(() {
                            isMuted = !isMuted;
                          });
                        },
                      ),

                      // زر إنهاء المكالمة (أحمر لامع)
                      _buildControlButton(
                        icon: Icons.call_end,
                        label: 'End Call',
                        color: Colors.redAccent,
                        onPressed: _endCall,
                        isEndCall: true,
                      ),

                      // زر الكاميرا/مكبر الصوت
                      _buildControlButton(
                        // *** التصحيح هنا: استخدام isVideoCall لتحديد الرمز ***
                        icon: widget.call.isVideoCall ? Icons.camera_alt : Icons.volume_up, // <== تم الإصلاح
                        label: widget.call.isVideoCall ? 'Camera' : 'Speaker', // <== تم الإصلاح
                        color: Colors.white24,
                        onPressed: () {
                          // وظيفة مكبر الصوت أو تبديل الكاميرا
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isEndCall = false,
  }) {
    // ... بقية الـ Widget ... (لا حاجة لتغييرها)
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isEndCall ? color : color.withOpacity(0.5),
              shape: BoxShape.circle,
              boxShadow: [
                if (isEndCall)
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: isEndCall ? Colors.white : Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
