import 'package:bikeblues/Authentication/U_signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPressed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInUserWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Check if email exists in vendors collection
        var vendorsQuery = await FirebaseFirestore.instance
            .collection('vendors')
            .where('email', isEqualTo: _emailController.text)
            .get();

        if (vendorsQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account already registered as Vendor.')),
          );
        } else {
          // Proceed with sign-in if email is not found in vendors collection
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully Signed In')),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'wrong-password':
            message = 'Wrong password provided.';
            break;
          case 'user-not-found':
            message = 'No user found for that email.';
            break;
          default:
            message = 'An error occurred. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      body: Stack(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.08),
                      child: Image.asset('assets/images/defaultLogo.png'),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'BikeBlues',
                      style: TextStyle(
                        fontSize: 24,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: <Color>[
                              Color(0xFF4E9CD4),
                              Color(0xFF53DDA3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(
                              Rect.fromLTWH(0, 0, screenWidth * 0.5, screenHeight * 0.05)),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.09),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Welcome Back! \n ',
                            style: TextStyle(
                              fontSize: 33,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0,
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
                            ),
                          ),
                          TextSpan(
                            text: 'Please Log In To Your Accounr ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.08,),
                    _buildTextFormField(
                      controller: _emailController,
                      hintText: 'Enter Your Email',
                      labelText: 'Email',
                      icon: Icons.mail_outline_sharp,
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    _buildTextFormField(
                      controller: _passwordController,
                      hintText: 'Enter Your Password',
                      labelText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    SizedBox(height: screenHeight * 0.15),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPressed = !_isPressed;
                        });
                        _signInUserWithEmailAndPassword();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xFF4E9CD4),
                              Color(0xFF53DDA3),
                            ],
                          ),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 140, vertical: 20),
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isPressed = !_isPressed;
                              });
                              _signInUserWithEmailAndPassword();
                            }
                          },
                          child: const Text('Sign In', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          style: const ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_)=> Signup()));
                          },
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(text: "Don't have an Account? ", style: TextStyle(color: Colors.white,)),
                                TextSpan(text: 'Sign Up!', style: TextStyle(color: Color.fromRGBO(83, 221, 163, 1), fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      controller: controller,
      obscureText: obscureText,
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Color.fromRGBO(83, 221, 163, 1)),
        labelText: labelText,
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
    );
  }
}
