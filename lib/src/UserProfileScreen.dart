import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikeblues/Authentication/SignInScreen.dart';

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

  bool _isEditing = false;
  bool _isUpdated = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.userData['name'] ?? '';
    addressController.text = widget.userData['address'] ?? '';
    emailController.text = widget.userData['email'] ?? '';
    phoneNumberController.text = widget.userData['phoneNumber'] ?? '';
    passwordController.text = widget.userData['password'] ?? '';

    nameController.addListener(_checkIfUpdated);
    addressController.addListener(_checkIfUpdated);
    emailController.addListener(_checkIfUpdated);
    phoneNumberController.addListener(_checkIfUpdated);
    passwordController.addListener(_checkIfUpdated);
  }

  void _checkIfUpdated() {
    setState(() {
      _isUpdated = nameController.text != widget.userData['name'] ||
          addressController.text != widget.userData['address'] ||
          emailController.text != widget.userData['email'] ||
          phoneNumberController.text != widget.userData['phoneNumber'];
          passwordController.text != widget.userData['password'] ?? '';
    });
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        )
      );
      setState(() {
        _isEditing = false;
        _isUpdated = false;
      });
    }
  }

  Future<bool> _showLogoutConfirmationDialog() async {
    return (await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: w * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new, 
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: h * 0.04),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        buildTextField(
                          controller: nameController,
                          label: 'Name',
                          icon: Icons.person,
                          readOnly: !_isEditing,
                        ),
                        SizedBox(height: h * 0.02),
                        buildTextField(
                          controller: addressController,
                          label: 'Address',
                          icon: Icons.home,
                          readOnly: !_isEditing,
                        ),
                        SizedBox(height: h * 0.02),
                        buildTextField(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.email,
                          readOnly: !_isEditing,
                        ),
                        SizedBox(height: h * 0.02),
                        buildTextField(
                          controller: phoneNumberController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          readOnly: !_isEditing,
                        ),
                        SizedBox(height: h * 0.1),
                        Container(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEditing
                                ? (_isUpdated 
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[400])
                                : Colors.blue[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: _isEditing && !_isUpdated ? 2 : 5,
                              shadowColor: _isEditing
                                ? (_isUpdated 
                                  ? Theme.of(context).primaryColor.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.5))
                                : Colors.blue.withOpacity(0.5),
                            ),
                            onPressed: _isEditing 
                              ? (_isUpdated ? _updateProfile : null)
                              : () {
                                  setState(() {
                                    _isEditing = true;
                                    _checkIfUpdated();
                                  });
                                },
                            child: AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isEditing && !_isUpdated 
                                  ? Colors.grey[600]
                                  : Colors.white,
                              ),
                              child: Text(_isEditing ? 'Update Profile' : 'Edit Profile'),
                            ),
                          ),
                        ),
                        SizedBox(height: 80), // Space for logout button
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () async {
                    bool confirmLogout = await _showLogoutConfirmationDialog();
                    if (confirmLogout) {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => UnifiedLoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool readOnly,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      readOnly: readOnly,
      validator: (value) => value!.isEmpty ? 'This field is required' : null,
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
