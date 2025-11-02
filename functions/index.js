/**
 * هذا الكود يعمل على خوادم Firebase (Cloud Functions).
 * وظيفته: الاستماع إلى إضافة رسالة جديدة في Firestore وإرسال إشعار فوري للمستلم.
 * * تم تحديث هذا الكود لاستخدام Firebase Functions v2 لتوافق مع Node 22.
 */

// استيراد المكتبات الضرورية
const admin = require('firebase-admin');

// استيراد وظائف Firestore من الإصدار v2
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

// تهيئة Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

/**
 * دالة: sendChatNotification
 * يتم تشغيلها عند إنشاء وثيقة (رسالة) جديدة في مسار: chat_rooms/{chatRoomId}/messages/{messageId}
 */
exports.sendChatNotification = onDocumentCreated('chat_rooms/{chatRoomId}/messages/{messageId}',
    async (event) => {
        // التحقق من وجود بيانات (رسالة جديدة)
        const snapshot = event.data;
        if (!snapshot) {
            console.log("No data associated with the event.");
            return null;
        }

        const newMessage = snapshot.data();
        const { senderId, receiverId, message, messageType } = newMessage;

        // تحديد محتوى الإشعار بناءً على نوع الرسالة
        const notificationBody = messageType === 'image' ? 'Sent an image 🖼️' : message;

        // 1. جلب اسم المستخدم المرسل
        const senderUser = await db.collection('users').doc(senderId).get();
        const senderData = senderUser.data();
        const senderUsername = senderData ? senderData.username : 'Someone';

        // 2. جلب بيانات المستلم (FCM Token وحالة الاتصال)
        const receiverUser = await db.collection('users').doc(receiverId).get();
        const receiverData = receiverUser.data();

        // يجب التأكد من حالة الاتصال والتوكن بشكل جيد
        const receiverIsOnline = receiverData && receiverData.isOnline === true;
        const receiverToken = receiverData ? receiverData.fcmToken : null;

        // شرط التخطي: لا نرسل الإشعار إذا كان المستخدم متصلاً أو إذا لم يكن لديه توكن مسجل.
        if (receiverIsOnline || !receiverToken) {
            console.log(`Skipping notification: Receiver is online or token is missing.`);
            // تأكد من استخدام return بدون قيمة لإنهاء الدالة
            return null;
        }

        // 3. بناء حمولة الإشعار
        const payload = {
            token: receiverToken,
            notification: {
                title: `رسالة جديدة من ${senderUsername}`,
                body: notificationBody,
                // **تم إزالة حقل 'sound':** // كانت خدمة FCM ترفض هذا الحقل ضمن 'notification' الرئيسي
                // مما أدى إلى خطأ: "Invalid JSON payload received. Unknown name 'sound'".
            },
            data: {
                // بيانات إضافية ترسل للتطبيق للتعامل مع النقر على الإشعار
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'senderId': senderId,
                // الوصول إلى متغيرات المسار يتم عبر event.params
                'chatRoomId': event.params.chatRoomId,
            }
        };

        // 4. إرسال الإشعار
        try {
            // نستخدم send() بدلاً من sendToDevice() لأنه payload يحتوي على token
            await admin.messaging().send(payload);
            console.log('Successfully sent message.');
            return null;
        } catch (error) {
            console.error('Error sending message:', error);
            return null;
        }
    }
);
