import 'dart:io';

import 'package:bikeblues/Authentication/V_SignIn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/Vendor_model.dart';

class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  State<VendorRegistrationScreen> createState() =>
      _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email,
      _password,
      _address,
      _phoneNumber,
      _storeImage,
      _shopName,
      _vendorName,
      _imageError;

  bool _isPressed = false;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _storeImage == null) {
      setState(() {
        _imageError = _storeImage == null ? 'Please upload an image' : null;
        _isPressed = !_isPressed;
      });
      return;
    }

    _formKey.currentState!.save();

    try {
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email!,
        password: _password!,
      );

      final storeImageUrl = await uploadImage(File(_storeImage!));

      final vendor = Vendor(
        id: userCredential.user!.uid,
        email: _email!,
        password: _password!,
        address: _address!,
        phoneNumber: _phoneNumber!,
        storeImage: storeImageUrl,
        shopName: _shopName!,
        vendorName: _vendorName!,
      );

      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendor.id)
          .set(vendor.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
       const  SnackBar(
            content: Text('Vendor registered successfully!',
                style: TextStyle(color: Colors.blue))),
      );

      // Navigate to vendor dashboard
      // Navigator.of(context).pushReplacementNamed('/vendor-dashboard', arguments: vendor);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/defaultLogo.png'),
                    SizedBox(width:  screenWidth  * 0.05,),
                    Text('Register Your Account', style: TextStyle(fontSize: 20, color: Colors.white)),
                  ],
                ),
                SizedBox(height: screenHeight * 0.04),
                _buildTextFormField(
                    'Shop Name', Icons.store, (value) => _shopName = value,
                        (value) {
                      if (value!.isEmpty) return 'Please Enter Shop Name';
                      return null;
                    }),
                SizedBox(height: screenHeight * 0.02),
                _buildTextFormField(
                    'Vendor Name', Icons.person, (value) => _vendorName = value,
                        (value) {
                      if (value!.isEmpty) return 'Please Enter Your Name';
                      return null;
                    }),
                SizedBox(height: screenHeight * 0.02),
                _buildTextFormField('Email', Icons.mail_outline_sharp,
                        (value) => _email = value, (value) {
                      if (value!.isEmpty) return 'Please Enter Email';
                      if (!value.contains('@')) return 'Invalid Email';
                      return null;
                    }, keyboardType: TextInputType.emailAddress),
                SizedBox(height: screenHeight * 0.02),
                _buildTextFormField('Password', Icons.lock_outline,
                        (value) => _password = value, (value) {
                      if (value!.isEmpty) return 'Please Enter Password';

                      return null;
                    }, obscureText: true),
                SizedBox(height: screenHeight * 0.02),
                _buildTextFormField('Address', Icons.location_on_rounded,
                        (value) => _address = value, (value) {
                      if (value!.isEmpty) return 'Please Enter Address';
                      return null;
                    }),
                SizedBox(height: screenHeight * 0.02),
                _buildTextFormField('Phone Number', Icons.phone_android,
                        (value) => _phoneNumber = value, (value) {
                      if (value!.isEmpty) return 'Please Enter Phone Number';
                      if (value.length != 11) return 'Invalid Phone Number';
                      return null;
                    }, keyboardType: TextInputType.phone),
                SizedBox(height: screenHeight * 0.03),
                _buildImagePicker(screenHeight, screenWidth),
                SizedBox(height: screenHeight * 0.02),
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
                          horizontal: 120, vertical: 20),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _submit,

                    child: const Text('Register', style: TextStyle(fontSize: 20)),
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
                        Navigator.of(context).push(MaterialPageRoute(builder: (_)=> VendorLoginScreen()));
                      },
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: "Already have an Account? ", style: TextStyle(color: Colors.white,)),
                            TextSpan(text: 'Sign In!', style: TextStyle(color: Color.fromRGBO(83, 221, 163, 1), fontSize: 18)),
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

  Widget _buildTextFormField(
      String label,
      IconData icon,
      void Function(String?) onSaved,
      String? Function(String?) validator, {
        bool obscureText = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color.fromRGBO(129, 129, 129, 1), fontSize: 18),
        prefixIcon: Icon(icon,color: Color.fromRGBO(83, 221, 163, 1) ),
        filled: true,
        fillColor: Color.fromRGBO(30, 30, 30, 1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,


      style: TextStyle(color: Colors.white),
    );
  }

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
