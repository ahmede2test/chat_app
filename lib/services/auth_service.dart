import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth get auth => _firebaseAuth;

  // **********************************************
  // ** 1. تهيئة الإشعارات (Firebase Messaging) **
  // **********************************************
  Future<void> setupFirebaseMessaging() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    // طلب الإذن بالإشعارات (مهم جداً لنظام iOS)
    await FirebaseMessaging.instance.requestPermission();

    final fcmToken = await FirebaseMessaging.instance.getToken();

    // حفظ الرمز (Token) في Firestore
    if (fcmToken != null) {
      await _firestore.collection('users').doc(user.uid).set(
        {'fcmToken': fcmToken},
        SetOptions(merge: true),
      );
      debugPrint('FCM Token updated and saved: $fcmToken');
    }

    // معالجة الإشعارات أثناء وجود التطبيق في المقدمة (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message notification: ${message.notification?.title} / ${message.notification?.body}');
    });

    // معالجة النقر على الإشعار عند فتح التطبيق من الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp event: ${message.data}');
    });
  }

  // **********************************************
  // ** 2. تحديث حالة المستخدم وإعداد الإشعارات **
  // **********************************************
  // تم تغيير الاسم إلى handlePostAuthSetup ليكون عاماً (Public)
  // للسماح لـ auth_screen.dart باستدعائها بعد المصادقة الاجتماعية.
  Future<void> handlePostAuthSetup(User user, {String? username, String? imageUrl}) async {
    // 1. إنشاء/تحديث مستند المستخدم في Firestore
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? 'social_user_${user.uid.substring(0, 8)}@anon.com',
      'username': username ?? user.displayName ?? user.email?.split('@')[0] ?? 'ChatUser',
      'imageUrl': imageUrl ?? user.photoURL ?? 'https://i.pravatar.cc/150?u=${user.uid}',
      'isOnline': true,
      'lastSeen': null,
    }, SetOptions(merge: true));

    // 2. تهيئة وحفظ رمز الإشعارات
    await setupFirebaseMessaging();
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // تنفيذ إعدادات ما بعد المصادقة
      await handlePostAuthSetup(userCredential.user!);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // Create a new user with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      UserCredential userCredential =
      await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);

      // تنفيذ إعدادات ما بعد المصادقة مع حفظ اسم المستخدم المخصص
      await handlePostAuthSetup(
        userCredential.user!,
        username: username,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // **************************************
  // ** 3. دالة تحديث حالة الاتصال (مطلوبة في main.dart) **
  // **************************************
  // هذه الدالة تم إضافتها لتصحيح الأخطاء في main.dart
  Future<void> updateUserStatus(bool isOnline) async {
    if (_firebaseAuth.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_firebaseAuth.currentUser!.uid)
          .set(
        {
          'isOnline': isOnline,
          'lastSeen': isOnline ? null : Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    }
  }

  // **************************************
  // ** 4. دالة تسجيل الخروج (signOut) **
  // **************************************
  Future<void> signOut() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // 1. تحديث حالة المستخدم إلى غير متصل باستخدام الدالة العامة
      await updateUserStatus(false);

      // 2. إزالة رمز الإشعارات
      await FirebaseMessaging.instance.deleteToken();
    }

    // 3. تسجيل الخروج من Firebase Auth
    await _firebaseAuth.signOut();
  }
}
