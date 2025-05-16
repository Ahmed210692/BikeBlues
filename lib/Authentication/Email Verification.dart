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
  bool _isResending = false;
  int _resendCount = 0;
  final int _maxResendAttempts = 3;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _checkEmailVerified(),
    );
  }

  Future<void> _sendVerificationEmail() async {
    if (_isResending || _resendCount >= _maxResendAttempts) return;

    setState(() {
      _isResending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _resendCount++;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification email sent to ${widget.email}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _checkEmailVerified() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;

      if (updatedUser != null && updatedUser.emailVerified) {
        _timer?.cancel();

        // Update Firestore document
        final collection = widget.role == 'Vendor' ? 'vendors' : 'users';
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .update({'emailVerified': true});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => UnifiedLoginScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking verification status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
              if (_resendCount < _maxResendAttempts) ...[
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isResending ? null : _sendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(83, 221, 163, 1),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(_isResending ? 'Sending...' : 'Resend Verification Email'),
                ),
                if (_resendCount > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Resend attempts remaining: ${_maxResendAttempts - _resendCount}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}