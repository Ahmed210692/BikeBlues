import 'package:bikeblues/Authentication/V_Signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/Vendor_model.dart';
import '../src/Vendor_Dashboard.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _email;
  String? _password;
  bool _isPressed = false;

  void login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isPressed = true;
    });

    try {

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email!,
        password: _password!,
      );

      DocumentSnapshot vendorData = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(userCredential.user!.uid)
          .get();

      if (vendorData.exists) {
        Vendor vendor = Vendor.fromMap(vendorData.data() as Map<String, dynamic>);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!', style: TextStyle(color: Colors.green))),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VendorDashboard(),
            settings: RouteSettings(arguments: vendor),
          ),
        );
      } else {
        // Vendor data does not exist, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor information not found. Please register as a vendor.', style: TextStyle(color: Colors.red))),
        );
        // Optionally sign out the user
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      // Handle authentication errors
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      // Handle other errors
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                        text: 'Welcome Back \n ',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0,

                        ),
                      ),
                      TextSpan(
                        text: 'Grow Your Buiness! ',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.normal,
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
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.07,),
                TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please Enter Email';
                    } else if (!value.contains('@')) {
                      return 'Invalid Email Address';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _email = value;
                  },
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
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: screenHeight * 0.04),
                TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please Enter Password';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _password = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter Your Password',
                    hintStyle: const TextStyle(color: Colors.white),
                    prefixIcon: Icon(Icons.mail_outline_sharp, color: Color.fromRGBO(83, 221, 163, 1)),
                    labelText: 'Password',
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
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                ),
               SizedBox(height: screenHeight * 0.2,),
                Container(
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
                    onPressed: login,

                    child: const Text('Sign In', style: TextStyle(fontSize: 20)),
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
                        Navigator.of(context).push(MaterialPageRoute(builder: (_)=> VendorRegistrationScreen()));
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
    );
  }
}
