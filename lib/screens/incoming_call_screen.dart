import 'package:flutter/material.dart';
import 'package:chat_app/services/call_service.dart';

// تأكد من المسار الصحيح
import '../ model/Call Data Model.dart';


// ******************************************************
// الثوابت لضمان المظهر المتناسق
// ******************************************************
const Color _kBackgroundColor = Color(0xFF1E1E1E);
const Color _kPrimaryColor = Color(0xFFD4AF37); // Gold-like
const Color _kTextColor = Colors.white;

class IncomingCallScreen extends StatelessWidget {
  final Call incomingCall;
  // تم إزالة 'const' من تهيئة الحقل
  // استخدام منشئ الـ Singleton CallService()
  final CallService _callService = CallService();

  // تم إزالة 'const' من المنشئ
  IncomingCallScreen({
    Key? key,
    required this.incomingCall,
  }) : super(key: key);

  // دالة للرد على المكالمة
  void _acceptCall(BuildContext context) async {
    // 1. تحديث حالة المكالمة إلى 'answered' في Firestore
    // نستخدم (!) للتأكيد أن callId لن يكون null لأنه مكالمة واردة
    await _callService.updateCallStatus(incomingCall.callId!, 'answered'); // <== تم الإصلاح هنا (إضافة !)

    // 2. الانتقال إلى شاشة المكالمة الفعلية كـ (مستجيب)
    _callService.navigateToCallScreen(context, incomingCall, isCaller: false);

    // 3. إغلاق شاشة الرنين بعد الرد
    Navigator.of(context).pop();
  }

  // دالة لرفض المكالمة
  void _rejectCall(BuildContext context) async {
    // 1. تحديث حالة المكالمة إلى 'rejected' في Firestore
    // نستخدم (!) للتأكيد أن callId لن يكون null لأنه مكالمة واردة
    await _callService.updateCallStatus(incomingCall.callId!, 'rejected'); // <== تم الإصلاح هنا (إضافة !)

    // 2. إغلاق شاشة الرنين
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // تحديد نوع المكالمة
    final String callType = incomingCall.isVideoCall ? 'Video' : 'Voice';
    final IconData icon = incomingCall.isVideoCall ? Icons.videocam : Icons.call;

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, _kBackgroundColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // معلومات المتصل
            Column(
              children: [
                const SizedBox(height: 50),
                Text(
                  callType,
                  style: const TextStyle(
                      color: _kPrimaryColor, fontSize: 24, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 20),
                Icon(icon, size: 80, color: _kPrimaryColor),
                const SizedBox(height: 30),
                Text(
                  incomingCall.callerName,
                  style: const TextStyle(
                      color: _kTextColor, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Incoming Call...',
                  style: TextStyle(color: _kTextColor, fontSize: 18),
                ),
              ],
            ),

            // أزرار التحكم
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // زر الرفض
                  _buildCallButton(
                    icon: Icons.call_end,
                    color: Colors.red.shade700,
                    label: 'Reject',
                    onPressed: () => _rejectCall(context),
                  ),

                  // زر القبول
                  _buildCallButton(
                    icon: Icons.call,
                    color: Colors.green.shade700,
                    label: 'Accept',
                    onPressed: () => _acceptCall(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 10,
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: _kTextColor, fontSize: 14),
        ),
      ],
    );
  }
}
