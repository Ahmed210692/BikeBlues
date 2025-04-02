import 'package:bikeblues/src/WelcomePage.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Start the opacity and scale animation
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Navigate to the Welcome screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _opacity = 0.0;
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Welcome()));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      body: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(seconds: 1),
          curve: Curves.easeOutBack, // This curve gives the "ease out from back" effect
          builder: (context, scale, child) {
            return AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              child: Transform.scale(
                scale: scale, // Apply the scale transformation
                child: Image.asset(
                  'assets/images/defaultLogo.png',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
