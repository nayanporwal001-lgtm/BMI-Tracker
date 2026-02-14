import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'bmi_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;
  late AnimationController _textController;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoScaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _logoController.forward();
    Timer(const Duration(milliseconds: 600), () {
      _textController.forward();
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      final user = FirebaseAuth.instance.currentUser;
      Widget nextScreen = const LoginScreen();

      if (user != null) {
        final snapshot = await FirebaseDatabase.instance.ref().child('users').child(user.uid).get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          if (data.containsKey('gender') && data.containsKey('dob')) {
            nextScreen = const DashboardScreen();
          } else {
            nextScreen = const BmiSetupScreen();
          }
        } else {
          nextScreen = const BmiSetupScreen();
        }
      }

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutQuart;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      print("App initialization error: $e");
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Image.asset(
                    'assets/logo.png',
                    width: 180,
                    height: 180,
                  ),
                ),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: SlideTransition(
                    position: _textSlideAnimation,
                    child: Text(
                      'BMI Tracker',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.blueAccent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _textFadeAnimation,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9933)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
