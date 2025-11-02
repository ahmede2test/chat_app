// استيراد نموذج الرسالة وحزمة dart:ui للضبابية
import 'dart:ui';
import 'package:flutter/material.dart';

import '../ model/message.dart';

// تعريف الألوان الجديدة الأكثر فخامة
const Color _kRoyalDark = Color(0xFF151515); // خلفية سوداء عميقة
const Color _kPrimaryBubbleColor = Color(0xFF252525); // لون الفقاعة الأساسي الفحمي
const Color _kNeonGlow = Color(0xFF3B3B3B); // لون الظل الداخلي (توهج النيون)

// تدرجات الألوان الفخمة للمؤشر
// تدرج ذهبي (للمرسل)
final LinearGradient _kGoldGradient = LinearGradient(
  colors: [Color(0xFFFFD700), Color(0xFFDAA520)], // ذهبي غني
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// تدرج لؤلؤي/أرجواني (للمستقبِل)
final LinearGradient _kPearlGradient = LinearGradient(
  colors: [Color(0xFFE0B0FF), Color(0xFF9370DB)], // أرجواني ولؤلؤي
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// مدة الرسوم المتحركة
const Duration _kAnimationDuration = Duration(milliseconds: 300);


class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final Message? repliedToMessage;
  final String receiverUserName;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.receiverUserName,
    this.repliedToMessage,
  }) : super(key: key);

  /// ******************************************************
  /// ** وظيفة بناء واجهة رسالة الرد (بالتصميم الملكي) **
  /// ******************************************************
  Widget _buildReplyContainer() {
    if (repliedToMessage == null) {
      return const SizedBox.shrink();
    }

    // تحديد اسم مرسل الرسالة المقتبس منها
    String senderName = repliedToMessage!.senderId == message.receiverId
        ? receiverUserName
        : repliedToMessage!.senderEmail.split('@')[0];

    // تحديد التدرج اللوني واسم اللون حسب المرسل
    final LinearGradient indicatorGradient = isMe ? _kGoldGradient : _kPearlGradient;
    final Color nameColor = isMe ? _kGoldGradient.colors.first : _kPearlGradient.colors.first;

    final isRepliedMessageImage = repliedToMessage!.messageType == 'image';
    const double thumbnailSize = 60;

    // استخدام AnimatedOpacity لإضافة تأثير تلاشي عند ظهور الحاوية
    return AnimatedOpacity(
      opacity: 1.0,
      duration: _kAnimationDuration,
      child: Container(
        padding: const EdgeInsets.all(0),
        margin: const EdgeInsets.only(bottom: 8),

        // ** إضافة إطار ذهبي فاخر **
        decoration: BoxDecoration(
          color: _kPrimaryBubbleColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: nameColor.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            // ظل خارجي عميق لإضافة العمق
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),

        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الشريط الجانبي الماسي (الفاخر) - بتدرج معدني
              Container(
                width: 7, // شريط أعرض
                decoration: BoxDecoration(
                  gradient: indicatorGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  // إضافة ظل داخلي خفيف للشريط ليظهر كقطعة معدنية لامعة
                  boxShadow: [
                    BoxShadow(
                      color: indicatorGradient.colors.first.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),

              // محتوى الرد نفسه
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // النص (اسم المرسل + محتوى الرسالة المقتبسة)
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // اسم المرسل بلون التدرج الفاخر (اسم المرسل هو الأهم)
                            Text(
                              senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: nameColor, // لون التوكيد المختار
                                fontSize: 14,
                                letterSpacing: 0.5, // مسافة أحرف أنيقة
                              ),
                            ),
                            const SizedBox(height: 4),
                            // محتوى الرسالة النصية أو فراغ للصورة
                            isRepliedMessageImage
                                ? const Text(
                              'Image Attachment',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                                : Text(
                              // قص النص المقتبس إذا كان طويلاً
                              repliedToMessage!.message.length > 40
                                  ? '${repliedToMessage!.message.substring(0, 40)}...'
                                  : repliedToMessage!.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      if (isRepliedMessageImage) ...[
                        const SizedBox(width: 8),
                        // الصورة المصغرة بحجم 60x60
                        SizedBox(
                          width: thumbnailSize,
                          height: thumbnailSize,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              repliedToMessage!.message,
                              width: thumbnailSize,
                              height: thumbnailSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: _kPrimaryBubbleColor,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white54,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ******************************************************
  /// ** وظيفة بناء محتوى الرسالة الأساسي (بتوهج النيون الداخلي) **
  /// ******************************************************
  Widget _buildMessageContent(BuildContext context) {
    final isImage = message.messageType == 'image';

    if (isImage) {
      // ** التعديل لجعل فقاعة الصورة فخمة وبارزة **
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. حاوية الصورة بإطار ذهبي أنيق
          Container(
            // الصورة أكبر وأكثر بروزاً
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 300),
            padding: const EdgeInsets.all(4), // بادينغ للإطار الذهبي
            decoration: BoxDecoration(
              gradient: _kGoldGradient, // الإطار الذهبي بتدرج لوني
              borderRadius: BorderRadius.circular(22), // زوايا مستديرة فاخرة
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                // ... منطق التنقل إلى ImageViewScreen ...
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18), // تجويف الإطار الداخلي
                child: Image.network(
                  message.message,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 150,
                      height: 150,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      color: _kPrimaryBubbleColor,
                      child: const Center(
                        child: Text(
                          'Image failed ❌',
                          style: TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 2. الوقت بنمط "حبة الوقت" تحت الصورة
          _buildTimePill(context, message),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),

          // الوقت بنمط "حبة الوقت" للرسائل النصية
          _buildTimePill(context, message),
        ],
      );
    }
  }

  /// ******************************************************
  /// ** وظيفة بناء "حبة الوقت" الأنيقة (للوضوح والثبات) **
  /// ******************************************************
  Widget _buildTimePill(BuildContext context, Message message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 6.0, right: 2.0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // خلفية شبه شفافة لضمان الوضوح
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${message.timestamp.toDate().hour.toString().padLeft(2, '0')}:${message.timestamp.toDate().minute.toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        // إذا كانت رسالة صورة، نقوم بعرضها مباشرة دون الفقاعة التقليدية
        if (message.messageType == 'image') ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: _buildMessageContent(context),
          )
        ]
        // إذا كانت رسالة نصية أو رد (داخل الفقاعة التقليدية)
        else ...[
          Container(
            constraints: const BoxConstraints(maxWidth: 320), // أقصى عرض للفقاعة
            decoration: BoxDecoration(
              color: _kPrimaryBubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(25), // زوايا ملكية
                topRight: const Radius.circular(25),
                bottomLeft: isMe ? const Radius.circular(25) : const Radius.circular(10),
                bottomRight: isMe ? const Radius.circular(10) : const Radius.circular(25),
              ),
              boxShadow: [
                // ظل خارجي (عمق)
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                // ** ظل داخلي (توهج النيون) **
                BoxShadow(
                  color: _kNeonGlow,
                  blurRadius: 5,
                  spreadRadius: -2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 18,
            ),
            margin: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عرض قسم الرد الملكي
                _buildReplyContainer(),

                // محتوى الرسالة الأساسي (سيكون نصاً هنا)
                _buildMessageContent(context),

                // ملاحظة: تم نقل الـ _buildTimePill إلى _buildMessageContent لتجنب التكرار
                // عند استخدام _buildReplyContainer و _buildMessageContent معًا
              ],
            ),
          ),
        ],
      ],
    );
  }
}
