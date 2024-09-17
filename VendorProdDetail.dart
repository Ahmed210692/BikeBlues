import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId; // To identify the product in Firestore

  const ProductDetailScreen({super.key, required this.productData, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isEditMode = false;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  File? _image;
  String? _imageUrl;
  bool _isSaving = false; // To manage save button state

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productData['name']);
    _priceController =
        TextEditingController(text: widget.productData['price'].toString());
    _descriptionController =
        TextEditingController(text: widget.productData['description']);
    _imageUrl = widget.productData['imageUrl'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    String imageUrl = _imageUrl!;

    // If a new image is selected, upload it to Firebase Storage
    if (_image != null) {
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
    }

    // Save the changes to Firestore
    try {
      await FirebaseFirestore.instance.collection('products').doc(
          widget.productId).update({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product updated successfully')));
      setState(() {
        _isEditMode = false;
      });
    } catch (e) {
      print('Error updating product: $e');
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Product' : widget.productData['name'],
            style: TextStyle(fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: screenHeight * 0.4,
                    width: screenWidth,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _image != null
                            ? FileImage(_image!) as ImageProvider
                            : NetworkImage(_imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: _isEditMode
                        ? IconButton(
                      icon: Icon(Icons.edit, color: Colors.white, size: 30),
                      onPressed: _pickImage,
                    )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _isEditMode
                        ? TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        labelStyle: TextStyle(color: Colors.white),
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
                    )
                        : Text(
                      'Name: ${widget.productData['name']}',
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _isEditMode
                        ? TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Price',
                        labelStyle: TextStyle(color: Colors.white),
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
                    )
                        : Text(
                      'Price: RS ${widget.productData['price']}',
                      style: const TextStyle(
                          fontSize: 24, color: Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _isEditMode
                        ? TextFormField(
                      controller: _descriptionController,
                      style: TextStyle(color: Colors.white),
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.white),
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
                    )
                        : Text(
                      'Description: ${widget.productData['description']}',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: _isEditMode ? Colors.green : Colors
                          .redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onPressed: _isEditMode
                        ? _saveChanges
                        : () {
                      setState(() {
                        _isEditMode = true;
                      });
                    },
                    child: Text(_isEditMode ? 'Save Changes' : 'Edit Product'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
