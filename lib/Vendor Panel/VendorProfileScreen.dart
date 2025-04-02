import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../model/Vendor_model.dart';

class VendorProfileScreen extends StatefulWidget {
  final Vendor vendor;

  const VendorProfileScreen({required this.vendor, Key? key}) : super(key: key);

  @override
  _VendorProfileScreenState createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _shopName, _vendorName, _address, _phoneNumber, _storeImageUrl;
  File? _newStoreImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _shopName = widget.vendor.shopName;
    _vendorName = widget.vendor.vendorName;
    _address = widget.vendor.address;
    _phoneNumber = widget.vendor.phoneNumber;
    _storeImageUrl = widget.vendor.storeImage;
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newStoreImage = File(pickedFile.path);
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      _formKey.currentState!.save();

      String? imageUrl = _storeImageUrl;
      if (_newStoreImage != null) {
        imageUrl = await uploadImage(_newStoreImage!);
      }

      final updatedVendor = Vendor(
        id: widget.vendor.id,
        email: widget.vendor.email,
        shopName: _shopName!,
        vendorName: _vendorName!,
        address: _address!,
        phoneNumber: _phoneNumber!,
        storeImage: imageUrl!,
      );

      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(updatedVendor.id)
          .update(updatedVendor.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Failed to update profile'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Store Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.primaryColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _newStoreImage != null
                                  ? Image.file(_newStoreImage!, fit: BoxFit.cover)
                                  : _storeImageUrl != null
                                  ? Image.network(
                                _storeImageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                              )
                                  : Icon(Icons.store,
                                  size: 80, color: theme.primaryColor),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),

              // Form Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextFormField(
                        'Shop Name',
                            (value) => _shopName = value,
                        _shopName!,
                        Icons.store,
                        theme,
                      ),
                      SizedBox(height: 16),
                      _buildTextFormField(
                        'Vendor Name',
                            (value) => _vendorName = value,
                        _vendorName!,
                        Icons.person,
                        theme,
                      ),
                      SizedBox(height: 16),
                      _buildTextFormField(
                        'Address',
                            (value) => _address = value,
                        _address!,
                        Icons.location_on,
                        theme,
                      ),
                      SizedBox(height: 16),
                      _buildTextFormField(
                        'Phone Number',
                            (value) => _phoneNumber = value,
                        _phoneNumber!,
                        Icons.phone,
                        theme,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.primaryColor,
                            ),
                          ),
                        )
                            : Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      String label,
      void Function(String?) onSaved,
      String initialValue,
      IconData icon,
      ThemeData theme, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      initialValue: initialValue,
      onSaved: onSaved,
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 16),
    );
  }
}