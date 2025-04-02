import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgetPasswordScreen extends StatefulWidget {
  final bool isVendor;
  const ForgetPasswordScreen({Key? key, this.isVendor = false}) : super(key: key);

  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First, verify if the email exists in the correct collection
      var query = await FirebaseFirestore.instance
          .collection(widget.isVendor ? 'vendors' : 'users')
          .where('email', isEqualTo: _emailController.text)
          .get();

      if (query.docs.isEmpty) {
        _showSnackBar(widget.isVendor
            ? 'No vendor account found with this email.'
            : 'No user account found with this email.');
        return;
      }

      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text
      );

      _showSnackBar(
          'Password reset link has been sent to ${_emailController.text}',
          color: Colors.green
      );

      // Optional: Navigate back after successful email send
      Navigator.of(context).pop();

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      _showSnackBar(message);
    } catch (e) {
      _showSnackBar('An unexpected error occurred.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.08),
                  child: Image.asset('assets/images/defaultLogo.png'),
                ),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 33,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: <Color>[
                          Color(0xFF4E9CD4),
                          Color(0xFF53DDA3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(
                        Rect.fromLTWH(0, 0, screenWidth * 0.5, screenHeight * 0.05),
                      ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  widget.isVendor
                      ? 'Reset Password for Vendor Account'
                      : 'Reset Password for User Account',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.05),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter Your Email',
                    hintStyle: const TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.mail_outline_sharp, color: Color.fromRGBO(83, 221, 163, 1)),
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Color.fromRGBO(129, 129, 129, 1), fontSize: 18),
                    filled: true,
                    fillColor: Color.fromRGBO(30, 30, 30, 1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    } else if (!value.contains('@')) {
                      return 'Invalid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.05),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4E9CD4), Color(0xFF53DDA3)],
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.25,
                            vertical: screenHeight * 0.010,
                          ),
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _isLoading ? null : _resetPassword,
                        child: Text(
                          'Reset Password',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}