import 'package:bikeblues/Authentication/SignupScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AdminPanel/Dashboard.dart';
import '../src/LandingPage.dart';
import '../Vendor Panel/Vendor_Dashboard.dart';
import '../model/Vendor_model.dart';
import 'ForgetPassword.dart';


class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPressed = false;
  bool _isVendorLogin = false;

  // Admin credentials
  final String adminPassword = 'Admin123';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isPressed) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPressed = true;
    });

    try {
      // Check for Admin Login first
      if (_emailController.text.toLowerCase() == 'admin' &&
          _passwordController.text == adminPassword) {
        _showSnackBar('Admin Login Successful!', color: Colors.green);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminDashboard()),
        );
        return;
      }

      // Check if the email exists in vendors collection
      var vendorsQuery = await FirebaseFirestore.instance
          .collection('vendors')
          .where('email', isEqualTo: _emailController.text)
          .get();

      if (_isVendorLogin) {
        // Vendor Login Flow
        if (vendorsQuery.docs.isEmpty) {
          _showSnackBar('No vendor account found with this email.');
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        DocumentSnapshot vendorData = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(userCredential.user!.uid)
            .get();
        String currentVendorId = userCredential.user!.uid;
        print('Current Vendor ID: $currentVendorId');

        if (vendorData.exists) {
          Vendor vendor = Vendor.fromMap(vendorData.data() as Map<String, dynamic>);
          _showSnackBar('Login successful!', color: Colors.green);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VendorDashboard(),
              settings: RouteSettings(arguments: vendor),
            ),
          );
        } else {
          _showSnackBar('Vendor information not found.');
          await FirebaseAuth.instance.signOut();
        }
      } else {
        // User Login Flow
        if (vendorsQuery.docs.isNotEmpty) {
          _showSnackBar('Account registered as Vendor. Please use Vendor Login.');
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Get current user ID
        String currentUserId = userCredential.user!.uid;
        print('Current User ID: $currentUserId');

        _showSnackBar('Successfully Signed In', color: Colors.green);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => Landingpage()));
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
          message = 'An error occurred: ${e.message}'; // Print the error message
      }
      _showSnackBar(message);
    } catch (e) {
      print('Unexpected error: $e'); // Print the unexpected error
      _showSnackBar('An unexpected error occurred.');
    } finally {
      setState(() {
        _isPressed = false;
      });
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and App Name
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
                            colors: const <Color>[
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
                    SizedBox(height: screenHeight * 0.05),

                    // Welcome Text
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _isVendorLogin ? 'Vendor Login\n' : 'Welcome Back!\n',
                            style: TextStyle(
                              fontSize: 33,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: const <Color>[
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
                            text: _isVendorLogin
                                ? 'Grow Your Business!'
                                : 'Please Log In To Your Account',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),

                    // Form Fields
                    _buildTextFormField(
                      controller: _emailController,
                      hintText: 'Enter Your Email',
                      labelText: 'Email',
                      icon: Icons.mail_outline_sharp,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (value.toLowerCase() != 'admin' && !value.contains('@')) {
                          return 'Invalid email address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    _buildTextFormField(
                      controller: _passwordController,
                      hintText: 'Enter Your Password',
                      labelText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ForgetPasswordScreen(
                                isVendor: _isVendorLogin,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Color(0xFF53DDA3)),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Login Button
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
                                horizontal: screenWidth * 0.3,
                                vertical: screenHeight * 0.015,
                              ),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _handleLogin,
                            child: Text(
                              _isVendorLogin ? 'Sign In' : 'Sign In',
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (_isPressed)
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                      ],
                    ),
                    // Sign Up Section
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DynamicSignup()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Don't have an Account? ",
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: _isVendorLogin ? 'Vendor Sign Up' : 'Sign Up!',
                              style: const TextStyle(
                                color: Color.fromRGBO(83, 221, 163, 1),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                   SizedBox(height: screenHeight * 0.04,),
                    // User/Vendor Switch Button
                    Container(
                      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF53DDA3)),
                      ),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isVendorLogin = !_isVendorLogin;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.2,
                            vertical: screenHeight * 0.010,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _isVendorLogin ? 'Switch to User Login' : 'Switch to Vendor Login',
                          style: const TextStyle(
                            color: Color(0xFF53DDA3),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: const Color.fromRGBO(83, 221, 163, 1)),
        labelText: labelText,
        labelStyle: const TextStyle(color: Color.fromRGBO(129, 129, 129, 1), fontSize: 18),
        filled: true,
        fillColor: const Color.fromRGBO(30, 30, 30, 1),
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