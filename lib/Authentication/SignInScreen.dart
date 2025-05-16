
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AdminPanel/Dashboard.dart';
import '../src/LandingPage.dart';
import '../Vendor Panel/Vendor_Dashboard.dart';
import '../model/Vendor_model.dart';
import '../model/User_model.dart';
import 'Email Verification.dart';
import 'ForgetPassword.dart';
import 'SignupScreen.dart';


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
  bool _obscurePassword = true;

  // Admin credentials
  final String adminPassword = 'Admin123';

  @override
  void initState() {
    super.initState();
  }

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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  // Modify the _handleLogin method in UnifiedLoginScreen
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

      // Check if user exists in the correct collection first
      final collection = _isVendorLogin ? 'vendors' : 'users';
      final querySnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('email', isEqualTo: _emailController.text)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showSnackBar('No ${_isVendorLogin ? 'vendor' : 'user'} account found with this email.');
        setState(() {
          _isPressed = false;
        });
        return;
      }

      // Sign in with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        _showSnackBar('Please verify your email before logging in. Check your inbox for the verification link.');
        setState(() {
          _isPressed = false;
        });
        return;
      }

      // Get the user document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _showSnackBar('Account data not found. Please contact support.');
        setState(() {
          _isPressed = false;
        });
        return;
      }

      // Update emailVerified status in Firestore
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userCredential.user!.uid)
          .update({'emailVerified': true});

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (_isVendorLogin) {
        try {
          Vendor vendor = Vendor.fromMap(userData);
          _showSnackBar('Welcome back!', color: Colors.green);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VendorDashboard(),
                settings: RouteSettings(arguments: vendor),
              ),
            );
          }
        } catch (e) {
          print("Error creating Vendor from Firestore data: $e");
          print("Data received: $userData");
          _showSnackBar('Error processing vendor data. Please contact support.');
          await FirebaseAuth.instance.signOut();
        }
      } else {
        try {
          AppUser user = AppUser.fromMap(userData);
          _showSnackBar('Welcome back!', color: Colors.green);
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => Landingpage(),
                settings: RouteSettings(arguments: user),
              ),
            );
          }
        } catch (e) {
          print("Error creating AppUser from Firestore data: $e");
          print("Data received: $userData");
          _showSnackBar('Error processing user data. Please contact support.');
          await FirebaseAuth.instance.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed login attempts. Please try again later.';
          break;
        default:
          message = 'Authentication failed: ${e.message}';
      }
      _showSnackBar(message);
    } catch (e) {
      print("Unexpected error during login: $e");
      _showSnackBar('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenHeight * 0.08),

                  // Logo or Brand Image could go here
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4E9CD4), Color(0xFF53DDA3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      _isVendorLogin ? Icons.store : Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Welcome Text
                  Text(
                    _isVendorLogin ? 'Vendor Login' : 'Welcome Back!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8),

                  Text(
                    _isVendorLogin
                        ? 'Manage your business efficiently'
                        : 'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: screenHeight * 0.06),

                  // Email Field
                  _buildAnimatedTextFormField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    label: 'Email',
                    hint: 'Enter your email address',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      } else if (value.toLowerCase() != 'admin' && !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Password Field
                  _buildAnimatedTextFormField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
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
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF53DDA3),
                      ),
                      child: Text('Forgot Password?'),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isPressed ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Color(0xFF53DDA3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                    child: _isPressed
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Sign Up Link
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DynamicSignup()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16),
                        children: [
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF53DDA3),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Toggle Switch
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Color(0xFF53DDA3), width: 1.5),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          setState(() {
                            _isVendorLogin = !_isVendorLogin;
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isVendorLogin ? Icons.person : Icons.store,
                                color: Color(0xFF53DDA3),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _isVendorLogin
                                    ? 'Switch to User Login'
                                    : 'Switch to Vendor Login',
                                style: TextStyle(
                                  color: Color(0xFF53DDA3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextFormField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffixIcon,
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          labelStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: validator,
      ),
    );
  }
}