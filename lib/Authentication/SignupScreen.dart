import 'dart:io';
import 'package:bikeblues/Authentication/SignInScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'Email Verification.dart';

class DynamicSignup extends StatefulWidget {
  const DynamicSignup({Key? key}) : super(key: key);

  @override
  _DynamicSignupState createState() => _DynamicSignupState();
}

class _DynamicSignupState extends State<DynamicSignup> {
  final _formKey = GlobalKey<FormState>();
  String? selectedRole;
  String? _storeImage;
  String? _imageError;
  String? _uploadedImageUrl;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _vendorNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _nameController.dispose();
    _shopNameController.dispose();
    _vendorNameController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _storeImage = pickedFile.path;
        _imageError = null;
      });
    }
  }

  Future<String> uploadImage(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('store_images/${DateTime.now().toIso8601String()}');
    final snapshot = await ref.putFile(image);
    return await snapshot.ref.getDownloadURL();
  }

  Future<bool> isEmailUnique(String email, String collection) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('email', isEqualTo: email)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  // Modify the registerUser and registerVendor methods in DynamicSignup

  Future<void> registerUser() async {
    try {
      final isUniqueInVendors = await isEmailUnique(_emailController.text, 'vendors');
      if (!isUniqueInVendors) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The email is already registered as a vendor.')),
        );
        return;
      }

      // Create user with email and password
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Create user document in Firestore first
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'id': userCredential.user!.uid,
        'name': _nameController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'phoneNumber': _phoneNumberController.text,
        'emailVerified': false,
      });


      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please verify your email.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to email verification screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: _emailController.text,
              role: 'User',
            ),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'The email is already registered as a user.';
          break;
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      print("Error in registerUser: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> registerVendor() async {
    try {
      final isUniqueInUsers = await isEmailUnique(_emailController.text, 'users');
      if (!isUniqueInUsers) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The email is already registered as a user.')),
        );
        return;
      }

      String storeImageUrl = '';
      if (_storeImage != null) {
        storeImageUrl = await uploadImage(File(_storeImage!));
        setState(() {
          _uploadedImageUrl = storeImageUrl;
        });
      }

      // Create user with email and password
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Create vendor document in Firestore first
      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(userCredential.user!.uid)
          .set({
        'id': userCredential.user!.uid,
        'vendorName': _vendorNameController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'phoneNumber': _phoneNumberController.text,
        'shopName': _shopNameController.text,
        'storeImage': storeImageUrl,
        'emailVerified': false,
      });



      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please verify your email.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to email verification screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: _emailController.text,
              role: 'Vendor',
            ),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'The email is already registered as a vendor.';
          break;
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      print("Error in registerVendor: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Update _register method to prevent navigation and let the registration methods handle it
//   void _register() async {
//     if (_formKey.currentState!.validate()) {
//       if (selectedRole == 'Vendor' && _storeImage == null) {
//         setState(() {
//           _imageError = 'Please upload an image.';
//         });
//         return;
//       }
//
//       if (selectedRole == 'User ') {
//         await registerUser();
//       } else if (selectedRole == 'Vendor') {
//         await registerVendor();
//       }
//
//       // Remove this line so the navigation in registerUser/registerVendor can work
//       // Navigator.of(context).pop();
//     }
//   }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (selectedRole == 'Vendor' && _storeImage == null) {
        setState(() {
          _imageError = 'Please upload an image.';
        });
        return;
      }

      if (selectedRole == 'User') {
        await registerUser();
      } else if (selectedRole == 'Vendor') {
        await registerVendor();
      }

     // Navigator.of(context).pop();
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^\d{11}$').hasMatch(value)) {
      return 'Phone number must be 11 digits';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(30, 30, 30, 1),
                Color.fromRGBO(20, 20, 20, 1),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.02),
                        child: Hero(
                          tag: 'logo',
                          child: Image.asset(
                            'assets/images/defaultLogo.png',
                            height: screenHeight * 0.12,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'BikeBlues',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(40, 40, 40, 1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Color.fromRGBO(40, 40, 40, 1),
                          decoration: InputDecoration(
                            labelText: 'Select Role',
                            labelStyle: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                          value: selectedRole,
                          items: ['User', 'Vendor']
                              .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              role,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                          validator: (value) =>
                          value == null ? 'Please select a role' : null,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      if (selectedRole == 'User ') ...[
                        _buildTextFormField(
                          controller: _nameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please Enter Name';
                            }
                            return null;
                          },
                          hintText: 'Enter Your Name',
                          labelText: 'Name',
                        ),
                      ],
                      if (selectedRole == 'Vendor') ...[
                        _buildTextFormField(
                          controller: _vendorNameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please Enter Name';
                            }
                            return null;
                          },
                          hintText: 'Enter Your Name',
                          labelText: 'Name',
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildTextFormField(
                          controller: _shopNameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please Enter Shop Name';
                            }
                            return null;
                          },
                          hintText: 'Enter Your Shop Name',
                          labelText: 'Shop Name',
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.02),
                      _buildTextFormField(
                        controller: _emailController,
                        validator: _validateEmail,
                        hintText: 'Enter Your Email',
                        labelText: 'Email',
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildTextFormField(
                        controller: _passwordController,
                        validator: _validatePassword,
                        hintText: 'Enter Your Password',
                        labelText: 'Password',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildTextFormField(
                        controller: _addressController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter Address';
                          }
                          return null;
                        },
                        hintText: 'Enter Your Address',
                        labelText: 'Address',
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildTextFormField(
                        controller: _phoneNumberController,
                        validator: _validatePhoneNumber,
                        hintText: 'Enter Your Phone Number',
                        labelText: 'Phone Number',
                        keyboardType: TextInputType.phone,
                      ),
                      if (selectedRole == 'Vendor') ...[
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          height: 56, // Same height as text fields
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(40, 40, 40, 1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _imageError != null ? Colors.red.shade300 : Colors.white24,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _storeImage == null
                              ? TextButton(
                            onPressed: pickImage,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  color: Color.fromRGBO(83, 221, 163, 1),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Upload Profile Image',
                                  style: TextStyle(
                                    color: Color.fromRGBO(83, 221, 163, 1),
                                    fontSize: 16,
                                  ),
                                ),
                                if (_imageError != null) ...[
                                  Spacer(),
                                  Text(
                                    _imageError!,
                                    style: TextStyle(
                                      color: Colors.red.shade300,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                              : GestureDetector(
                            onTap: pickImage,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(_storeImage!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.03),
                      Container(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(83, 221, 163, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => UnifiedLoginScreen()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 16),
                            children: [
                              TextSpan(
                                text: 'Already have an Account? ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              TextSpan(
                                text: 'Sign In!',
                                style: TextStyle(
                                  color: Color.fromRGBO(83, 221, 163, 1),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String hintText,
    required String labelText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(40, 40, 40, 1),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white38),
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.white70),
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color.fromRGBO(83, 221, 163, 1), width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade300, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red.shade300, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        obscureText: obscureText,
      ),
    );
  }
}