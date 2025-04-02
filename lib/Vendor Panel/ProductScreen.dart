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
  bool _isLoading = false;

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

      if (fileSize > 2 * 1024 * 1024) {
        setState(() {
          _image = null;
          _imageError = "Image size exceeds 2MB. Please select a smaller image.";
        });
      } else {
        setState(() {
          _image = file;
          _imageError = null;
        });
      }
    }
  }

  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate() || _image == null) {
      setState(() {
        _imageError = _image == null ? "Please upload an image" : null;
      });
      return;
    }

    setState(() => _isLoading = true);
    _formKey.currentState?.save();

    try {
      // Upload image
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('${DateTime.now().millisecondsSinceEpoch}_${path.basename(_image!.path)}');
      await ref.putFile(_image!);
      final imageUrl = await ref.getDownloadURL();

      // Upload product data
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('products').add({
        'name': _name,
        'description': _description,
        'price': _price,
        'imageUrl': imageUrl,
        'vendorId': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Product uploaded successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to upload product'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(24),
              children: [
                // Image Upload Section
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _imageError != null ? Colors.red : theme.colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: _image == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Add Product Image',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (_imageError != null) ...[
                          SizedBox(height: 8),
                          Text(
                            _imageError!,
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Product Name Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter product name';
                    return null;
                  },
                  onSaved: (value) => _name = value!,
                ),
                SizedBox(height: 16),

                // Price Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixIcon: Icon(Icons.attach_money_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter price';
                    if (double.tryParse(value!) == null) return 'Please enter a valid number';
                    return null;
                  },
                  onSaved: (value) => _price = double.parse(value!),
                ),
                SizedBox(height: 16),

                // Description Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter description';
                    return null;
                  },
                  onSaved: (value) => _description = value!,
                ),
                SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _uploadProduct,
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(
                    'Upload Product',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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