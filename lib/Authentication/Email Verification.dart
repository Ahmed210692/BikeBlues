import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'SignInScreen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String role; // 'User' or 'Vendor'

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    required this.role
  }) : super(key: key);

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Send verification email immediately
    _sendVerificationEmail();

    // Check verification status periodically
    _timer = Timer.periodic(
        const Duration(seconds: 3),
            (_) => _checkEmailVerified()
    );
  }

  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent to ${widget.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send verification email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkEmailVerified() async {
    // Reload the user to get the latest verification status
    await FirebaseAuth.instance.currentUser?.reload();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      // Stop the timer
      _timer?.cancel();

      // Navigate to login screen based on role
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => UnifiedLoginScreen(), // Assuming you have this screen
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/defaultLogo.png', height: 100),
              const SizedBox(height: 20),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'A verification email has been sent to ${widget.email}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Please check your email and click the verification link.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _sendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(83, 221, 163, 1),
                ),
                child: const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}