import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/screens/auth_screen.dart';
import 'package:chat_app/screens/conversation_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  // Function to determine the next screen based on auth status
  void _navigateToNextScreen() {
    // Check if a user is currently signed in
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;

    final Widget nextScreen = isAuthenticated
        ? const ConversationListScreen()
        : const AuthScreen();

    // Navigate after the delay using pushReplacement for a clean transition
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => nextScreen,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Navigate after the animation duration (2.5 seconds)
    Future.delayed(const Duration(milliseconds: 2500), _navigateToNextScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          // Luxurious color gradient from dark blue to lighter blue/black
          gradient: RadialGradient(
            colors: [
              Color(0xFF1A237E), // Indigo 900 (Dark Blue)
              Color(0xFF0D47A1), // Blue 900
              Color(0xFF000000), // Black
            ],
            stops: [0.0, 0.5, 1.0],
            center: Alignment.center,
            radius: 1.5,
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 2000), // Animation duration
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // **1. Hero Transition & Shimmer Effect for the Logo**
                      // (This must be repeated in AuthScreen/ConversationListScreen with the same tag)
                      Hero(
                        tag: 'chatIcon', // Tag for the cinematic transition
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [
                                Color(0xFFD4AF37), // Gold
                                Color(0xFFFFD700), // Bright Gold
                                Color(0xFFD4AF37),
                              ],
                              tileMode: TileMode.mirror,
                            ).createShader(bounds);
                          },
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 150,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // **2. App Title: AURA CHAT**
                      ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            colors: [
                              Color(0xFFD4AF37), // Gold
                              Color(0xFFFFD700), // Bright Gold
                              Color(0xFFD4AF37),
                            ],
                            tileMode: TileMode.mirror,
                          ).createShader(bounds);
                        },
                        child: Text(
                          'AURA CHAT', // الاسم الجديد الأكثر فخامة
                          style: GoogleFonts.poppins(
                            fontSize: 36, // حجم أكبر
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4, // تباعد أحرف أكبر لزيادة الفخامة
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
