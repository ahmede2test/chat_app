import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // REQUIRED for FCM

import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/screens/auth_screen.dart';
import 'package:chat_app/screens/conversation_list_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/notification_service.dart'; // Import the service
import 'package:chat_app/services/call_service.dart'; // Import CallService

// ******************************************************
// Note: navigatorKey and onSelectNotification are now imported from notification_service.dart
// ******************************************************
// Initialize the service instance globally
final NotificationService notificationService = NotificationService();


// ******************************************************
// Placeholder screen for handling the deep link action
// ******************************************************
class PlaceholderChatScreen extends StatelessWidget {
  const PlaceholderChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract parameters passed from the notification payload
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final chatRoomId = arguments?['chatRoomId'] ?? 'N/A';
    final senderId = arguments?['senderId'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Room (Placeholder)', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B1B1B),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: Container(
        color: const Color(0xFF1B1B1B),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                  'You navigated here from a Notification!',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 20),
              Text('Chat Room ID: $chatRoomId', style: const TextStyle(color: Colors.grey)),
              Text('Sender ID: $senderId', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Go to Conversations', style: TextStyle(color: Color(0xFF1B1B1B), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ******************************************************
// Top-level function to handle Firebase messages when the app is in the background or terminated.
// ******************************************************
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized again for background tasks
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize the local notification service
  await notificationService.initialize();
  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        // Adding CallService to providers
        Provider(create: (context) => CallService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ******************************************************
    // Handle notification tap when the app is TERMINATED (closed)
    // ******************************************************
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final chatRoomId = message.data['chatRoomId'];
        final senderId = message.data['senderId'];
        if (chatRoomId != null && senderId != null) {
          final payload = '/chat?chatRoomId=$chatRoomId&senderId=$senderId';
          Future.delayed(Duration.zero, () {
            // *** تم الإصلاح: استدعاء الدالة التوب-ليفيل مباشرة ***
            onSelectNotification(payload);
          });
        }
      }
    });

    // ******************************************************
    // Handle notification tap when the app is in the BACKGROUND
    // ******************************************************
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final chatRoomId = message.data['chatRoomId'];
      final senderId = message.data['senderId'];
      if (chatRoomId != null && senderId != null) {
        final payload = '/chat?chatRoomId=$chatRoomId&senderId=$senderId';
        // *** تم الإصلاح: استدعاء الدالة التوب-ليفيل مباشرة ***
        onSelectNotification(payload);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check if the user is authenticated before updating status
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.auth.currentUser != null) {
      if (state == AppLifecycleState.resumed) {
        authService.updateUserStatus(true); // User is online
      } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        authService.updateUserStatus(false); // User is offline
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 1. Assign the global key to MaterialApp (imported from notification_service)
      navigatorKey: navigatorKey,

      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1B1B1B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B1B1B),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFD4AF37),
          secondary: const Color(0xFFD4AF37),
        ),
        useMaterial3: true,
      ),

      // 2. Define routes for deep linking
      routes: {
        '/chat': (context) => const PlaceholderChatScreen(),
        '/conversations': (context) => const ConversationListScreen(),
        // Make sure you define the CallScreen route if you use pushNamed later
      },

      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF1B1B1B),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD4AF37),
                ),
              ),
            );
          }
          if (userSnapshot.hasData) {
            final authService = Provider.of<AuthService>(ctx, listen: false);
            authService.updateUserStatus(true);
            authService.setupFirebaseMessaging();
            // 3. Navigate to the conversations screen if authenticated
            return const ConversationListScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
