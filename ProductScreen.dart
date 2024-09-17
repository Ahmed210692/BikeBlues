import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPressed = false;

  String _name = '';
  double _price = 0.0;
  String _description = '';
  File? _image;
  String? _imageError;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();

      if (fileSize > 2 * 1024 * 1024) {  // Check if the file size is more than 2MB
        setState(() {
          _image = null;
          _imageError = "Image size exceeds 2MB. Please select a smaller image.";
        });
      } else {
        setState(() {
          _image = file;
          _imageError = null;  // Reset the error when an image is picked
        });
      }
    }
  }

  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate() || _image == null) {
      setState(() {
        _imageError = _image == null ? "Please upload an image" : null;
        _isPressed = !_isPressed;
      });
      return;
    }

    _formKey.currentState?.save();
    String imageUrl = '';

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('${path.basename(_image!.path)}');
      await ref.putFile(_image!);
      imageUrl = await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;  // Get the current user
      await FirebaseFirestore.instance.collection('products').add({
        'name': _name,
        'description': _description,
        'price': _price,
        'imageUrl': imageUrl,
        'vendorId': user?.uid,  // Save the vendor's UID to associate the product with this vendor
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product uploaded successfully')));
      Navigator.of(context).pop();  // Return to the previous screen after successful upload
    } catch (e) {
      print('Error adding product: $e');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.04),
                Container(
                  height: screenHeight * 0.3,
                  width: screenWidth * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                  ),
                  child: Center(
                    child: TextButton(
                      onPressed: _pickImage,
                      child: _image == null
                          ? Text('Add Product Image')
                          : Image.file(_image!),
                    ),
                  ),
                ),
                if (_imageError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _imageError!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  decoration: InputDecoration(
                      labelText: 'Product Name',
                      prefixIcon: Icon(Icons.store),
                      border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Enter Product Name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  decoration: InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.price_change_outlined),
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Enter Product price';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _price = double.parse(value!);
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: 10,
                  decoration: InputDecoration(
                      hintText: 'Description', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Enter Product description';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _description = value!;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: StadiumBorder(),
                    backgroundColor: _isPressed ? Colors.blue : Colors.grey,
                  ),
                  onPressed: _uploadProduct,
                  child: Text('Upload Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
