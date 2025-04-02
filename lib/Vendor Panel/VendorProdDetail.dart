import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productData['name']);
    _priceController = TextEditingController(text: widget.productData['price'].toString());
    _descriptionController = TextEditingController(text: widget.productData['description']);
    _imageUrl = widget.productData['imageUrl'];
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
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
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product updated successfully')),
      );
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

  // New method to build rating statistics
  Widget _buildRatingStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        Map<int, int> ratingDistribution = {
          1: 0, 2: 0, 3: 0, 4: 0, 5: 0
        };
        double totalRating = 0;

        snapshot.data!.docs.forEach((doc) {
          final rating = (doc.data() as Map<String, dynamic>)['rating'] as double;
          totalRating += rating;
          ratingDistribution[rating.toInt()] =
              (ratingDistribution[rating.toInt()] ?? 0) + 1;
        });

        final totalReviews = snapshot.data!.docs.length;
        final averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Rating: ${averageRating.toStringAsFixed(1)} / 5',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
            ),
            Text(
              'Total Reviews: $totalReviews',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            ...List.generate(5, (index) {
              final starRating = 5 - index;
              final count = ratingDistribution[starRating] ?? 0;
              return _buildRatingBar(starRating, count, totalReviews);
            }),
          ],
        );
      },
    );
  }

  // New method to build individual rating bars
  Widget _buildRatingBar(int stars, int count, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
              '$stars Star',
              style: TextStyle(color: Colors.white)
          ),
          SizedBox(width: 10),
          Expanded(
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          SizedBox(width: 10),
          Text(
              '$count',
              style: TextStyle(color: Colors.white)
          )
        ],
      ),
    );
  }

  // New method to build reviews list
  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Reviews',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              ),
            ),
            ...snapshot.data!.docs.map((doc) {
              final reviewData = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(
                  reviewData['userName'] ?? 'Anonymous',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingBarIndicator(
                      rating: reviewData['rating'],
                      itemBuilder: (context, index) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 20.0,
                    ),
                    Text(
                      reviewData['review'],
                      style: TextStyle(color: Colors.white70),
                    )
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          _isEditMode ? 'Edit Product' : widget.productData['name'],
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      ),
      body: _isSaving
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: screenHeight * 0.4,
              width: screenWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
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
                  color: Colors.white,
                ),
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
                  fontSize: 24,
                  color: Colors.redAccent,
                ),
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
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),

            // Rating Statistics Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildRatingStatistics(),
            ),

            // Reviews List Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildReviewsList(),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: _isEditMode ? Colors.green : Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                      ),
                      onPressed: _isEditMode
                          ? _saveChanges
                          : () {
                        setState(() {
                          _isEditMode = true;
                        });
                      },
                      child: Text(
                        _isEditMode ? 'Save Changes' : 'Edit Product',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}