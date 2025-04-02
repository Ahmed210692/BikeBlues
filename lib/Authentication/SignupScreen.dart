import 'dart:io';
import 'package:bikeblues/Authentication/SignInScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../model/User_model.dart';
import '../model/Vendor_model.dart';
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
  String? _uploadedImageUrl; // Store the uploaded image URL
  bool _obscurePassword = true; // For password visibility toggle

  // Controllers for shared fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  // User-specific controller
  final TextEditingController _nameController = TextEditingController();

  // Vendor-specific controllers
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
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
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

  Future<void> registerUser() async {
    try {
      final isUniqueInVendors = await isEmailUnique(_emailController.text, 'vendors');
      if (!isUniqueInVendors) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The email is already registered as a vendor.')),
        );
        return;
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Send the user to email verification screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
              email: _emailController.text,
              role: 'User'
          ),
        ),
      );

      // Only save user to Firestore if email is verified
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'id': userCredential.user!.uid,
        'name': _nameController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'phoneNumber': _phoneNumberController.text,
        'emailVerified': false // Add this flag
      });

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'The email is already registered as a user.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Send the vendor to email verification screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
              email: _emailController.text,
              role: 'Vendor'
          ),
        ),
      );

      // Only save vendor to Firestore if email is verified
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
        'emailVerified': false // Add this flag
      });

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'The email is already registered as a vendor.';
          break;
        default:
          message = 'An error occurred: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (selectedRole == 'Vendor' && _storeImage == null) {
        setState(() {
          _imageError = 'Please upload an image.';
        });
        return;
      }

      if (selectedRole == 'User ') {
        await registerUser ();
      } else if (selectedRole == 'Vendor') {
        await registerVendor();
      }

      Navigator.of(context).pop();
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.01),
                      child: Image.asset('assets/images/defaultLogo.png', height: screenHeight * 0.08,),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    const Text(
                      'BikeBlues',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),

                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Role',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      value: selectedRole,
                      items: ['User ', 'Vendor']
                          .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role, style: TextStyle(color: Colors.grey)),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a role' : null,
                    ),
                    SizedBox(height: screenHeight * 0.04),



                    if (selectedRole == 'User ') ...[
                      SizedBox(height: screenHeight * 0.02),
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
                        icon: Icons.person,
                      ),
                    ],

                    // Show vendor-specific fields if the selected role is 'Vendor'
                    if (selectedRole == 'Vendor') ...[
                      SizedBox(height: screenHeight * 0.02),
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
                        icon: Icons.person,
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
                        icon: Icons.store,
                      ),
                    ],

                    // Continue with the rest of your fields...
                    SizedBox(height: screenHeight * 0.02),
                    _buildTextFormField(
                      controller: _emailController,
                      validator: _validateEmail,
                      hintText: 'Enter Your Email',
                      labelText: 'Email',
                      icon: Icons.mail_outline_sharp,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    _buildTextFormField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      hintText: 'Enter Your Password',
                      labelText: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
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
                      icon: Icons.home_outlined,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    _buildTextFormField(
                      controller: _phoneNumberController,
                      validator: _validatePhoneNumber,
                      hintText: 'Enter Your Phone Number',
                      labelText: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone_android_outlined,
                    ),
                    if (selectedRole == 'Vendor') ...[
                      SizedBox(height: screenHeight * 0.02),
                      _buildImagePicker(screenHeight, screenWidth),
                    ],
                    SizedBox(height: screenHeight * 0.02),
                    ElevatedButton(
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          style: const ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => UnifiedLoginScreen()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Already have an Account? ',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'Sign In!',
                                  style: TextStyle(
                                    color: Color.fromRGBO(83, 221, 163, 1),
                                    fontSize: 18,
                                  ),
                                ),
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
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String hintText,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.white,),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(18),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(18),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      obscureText: obscureText,
    );
  }
  ///////////////////
  Widget _buildImagePicker(double screenHeight, double screenWidth) {
    return Container(
      height: screenHeight * 0.2,
      width: screenWidth * 0.6,

      decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
          border: Border.fromBorderSide(BorderSide(color: Colors.white))
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextButton(
                onPressed: pickImage,
                child: _storeImage == null
                    ? const Text('Upload Profile Image', style: TextStyle(color: Color.fromRGBO(83, 221, 163, 1)),)
                    : Image.file(File(_storeImage!), fit: BoxFit.cover),
              ),
            ),
            if (_imageError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_imageError!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}