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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _storeImageUrl;

      if (_newStoreImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('store_images')
            .child('${widget.vendor.id}.jpg');
        await ref.putFile(_newStoreImage!);
        imageUrl = await ref.getDownloadURL();
      }

      final updatedVendor = Vendor(
        id: widget.vendor.id,
        email: widget.vendor.email,
        address: _address!,
        phoneNumber: _phoneNumber!,
        storeImage: imageUrl!,
        shopName: _shopName!,
        vendorName: _vendorName!,
      );

      await FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.vendor.id)
          .update(updatedVendor.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue[800]!,
                          Colors.blue[600]!,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 10,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Store Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Transform.translate(
                offset: Offset(0, -60),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
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
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                value: progress.expectedTotalBytes != null
                                                    ? progress.cumulativeBytesLoaded /
                                                        progress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        )
                                      : Icon(Icons.store,
                                          size: 60, color: Colors.grey[400]),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
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

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Store Information',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            SizedBox(height: 25),
                            _buildTextFormField(
                              'Shop Name',
                              (value) => _shopName = value,
                              _shopName!,
                              theme,
                            ),
                            SizedBox(height: 20),
                            _buildTextFormField(
                              'Vendor Name',
                              (value) => _vendorName = value,
                              _vendorName!,
                              theme,
                            ),
                            SizedBox(height: 20),
                            _buildTextFormField(
                              'Address',
                              (value) => _address = value,
                              _address!,
                              theme,
                            ),
                            SizedBox(height: 20),
                            _buildTextFormField(
                              'Phone Number',
                              (value) => _phoneNumber = value,
                              _phoneNumber!,
                              theme,
                              keyboardType: TextInputType.phone,
                            ),
                            
                            SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                backgroundColor: Colors.blue[600],
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 25,
                                      width: 25,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
    ThemeData theme, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          errorStyle: TextStyle(color: Colors.red[400]),
        ),
        initialValue: initialValue,
        onSaved: onSaved,
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}