import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isEditing = false; // Flag to track edit mode
  bool _isUpdated = false; // Flag to track if data is modified

  @override
  void initState() {
    super.initState();
    nameController.text = widget.userData['name'] ?? '';
    addressController.text = widget.userData['address'] ?? '';
    emailController.text = widget.userData['email'] ?? '';
    phoneNumberController.text = widget.userData['phoneNumber'] ?? '';
    passwordController.text = widget.userData['password'] ?? '';

    // Add listeners to detect changes
    nameController.addListener(_checkIfUpdated);
    addressController.addListener(_checkIfUpdated);
    emailController.addListener(_checkIfUpdated);
    phoneNumberController.addListener(_checkIfUpdated);
    passwordController.addListener(_checkIfUpdated);
  }

  // Method to check if any text field has been changed
  void _checkIfUpdated() {
    setState(() {
      _isUpdated = nameController.text != widget.userData['name'] ||
          addressController.text != widget.userData['address'] ||
          emailController.text != widget.userData['email'] ||
          phoneNumberController.text != widget.userData['phoneNumber'];
          passwordController.text != widget.userData['password'] ?? '';

    });
  }

  // Method to update profile
  Future<void> _updateProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && _formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': nameController.text,
        'address': addressController.text,
        'email': emailController.text,
        'phoneNumber': phoneNumberController.text,
        'password':passwordController.text
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      setState(() {
        _isEditing = false; // Exit edit mode after updating
        _isUpdated = false; // Reset the update flag
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Change Your Profile!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20,),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name', focusColor: Colors.black,
                  prefixIcon: Icon(Icons.person, color: Color.fromRGBO(83, 221, 163, 1)),
                  hintText: 'Enter your name',
                  hintStyle: const TextStyle(color: Colors.black),

                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
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
                readOnly: !_isEditing,
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',focusColor: Colors.black,
                  prefixIcon: Icon(Icons.home, color: Color.fromRGBO(83, 221, 163, 1)),
                  hintText: 'Enter your address',
                  hintStyle: const TextStyle(color: Colors.black),

                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
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
                readOnly: !_isEditing,
                validator: (value) =>
                value!.isEmpty ? 'Enter your address' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Color.fromRGBO(83, 221, 163, 1)),
                  hintText: 'Enter your email',
                  hintStyle: const TextStyle(color: Colors.black),

                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
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
                readOnly: !_isEditing,
                validator: (value) =>
                value!.isEmpty ? 'Enter your email' : null,
              ),

              // const SizedBox(height: 20),
              // TextFormField(
              //   controller: passwordController,
              //   decoration: InputDecoration(
              //     labelText: 'Password',
              //     prefixIcon: Icon(Icons.lock_outline_rounded, color: Color.fromRGBO(83, 221, 163, 1)),
              //     hintText: 'Enter your password',
              //     hintStyle: const TextStyle(color: Colors.black),
              //
              //     enabledBorder: OutlineInputBorder(
              //       borderSide: BorderSide(color: Colors.deepPurpleAccent),
              //       borderRadius: BorderRadius.circular(18),
              //     ),
              //     focusedBorder: OutlineInputBorder(
              //       borderSide: BorderSide(color: Colors.blue),
              //       borderRadius: BorderRadius.circular(18),
              //     ),
              //     errorBorder: OutlineInputBorder(
              //       borderSide: BorderSide(color: Colors.red),
              //       borderRadius: BorderRadius.circular(18),
              //     ),
              //   ),
              //   readOnly: !_isEditing,
              //   validator: (value) =>
              //   value!.isEmpty ? 'Enter your password' : null,
              // ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',focusColor: Colors.black,
                  prefixIcon: Icon(Icons.phone, color: Color.fromRGBO(83, 221, 163, 1)),
                  hintText: 'Enter your phone number',
                  hintStyle: const TextStyle(color: Colors.black),

                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                readOnly: !_isEditing,
                validator: (value) =>
                value!.isEmpty ? 'Enter your phone number' : null,
              ),
              const SizedBox(height: 40),
              _isEditing
                  ? ElevatedButton(
                onPressed: _isUpdated ? _updateProfile : null,
                child: const Text('Update Profile'),
              )
                  : ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                    _checkIfUpdated();
                  });
                },
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }
}
