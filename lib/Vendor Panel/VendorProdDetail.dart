import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const ProductDetailScreen({super.key, required this.productData, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isEditMode = false;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  final ScrollController _scrollController = ScrollController();

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

    try {
      await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
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

  Widget _buildRatingStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        double totalRating = 0;

        snapshot.data!.docs.forEach((doc) {
          final rating = (doc.data() as Map<String, dynamic>)['rating'] as double;
          totalRating += rating;
          ratingDistribution[rating.toInt()] = (ratingDistribution[rating.toInt()] ?? 0) + 1;
        });

        final totalReviews = snapshot.data!.docs.length;
        final averageRating = totalReviews > 0 ? (totalRating / totalReviews).toDouble() : 0.0;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      RatingBarIndicator(
                        rating: averageRating,
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                      ),
                      Text(
                        '$totalReviews Reviews',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 100,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Column(
                        children: List.generate(5, (index) {
                          final starRating = 5 - index;
                          final count = ratingDistribution[starRating] ?? 0;
                          return _buildRatingBar(starRating, count, totalReviews);
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$stars', style: TextStyle(color: Colors.white, fontSize: 12)),
          Icon(Icons.star, color: Colors.amber, size: 12),
          SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? count / total : 0,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 4,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text('$count', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Customer Reviews',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ...snapshot.data!.docs.map((doc) {
              final reviewData = doc.data() as Map<String, dynamic>;
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Text(
                            (reviewData['userName'] ?? 'A')[0].toUpperCase(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reviewData['userName'] ?? 'Anonymous',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            RatingBarIndicator(
                              rating: reviewData['rating'],
                              itemBuilder: (context, index) => Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 16.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      reviewData['review'],
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
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
    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      body: _isSaving
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.5,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: _image != null
                                  ? FileImage(_image!) as ImageProvider
                                  : NetworkImage(_imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        if (_isEditMode)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: FloatingActionButton(
                              onPressed: _pickImage,
                              child: Icon(Icons.edit),
                              backgroundColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isEditMode
                            ? TextFormField(
                                controller: _nameController,
                                style: TextStyle(color: Colors.white, fontSize: 24),
                                decoration: InputDecoration(
                                  labelText: 'Product Name',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                              )
                            : Text(
                                widget.productData['name'],
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                        SizedBox(height: 8),
                        _isEditMode
                            ? TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: Colors.white, fontSize: 20),
                                decoration: InputDecoration(
                                  labelText: 'Price',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  prefixText: 'RS ',
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                              )
                            : Text(
                                'RS ${widget.productData['price']}',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        SizedBox(height: 24),
                        _isEditMode
                            ? TextFormField(
                                controller: _descriptionController,
                                style: TextStyle(color: Colors.white),
                                maxLines: 5,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                              )
                            : Text(
                                widget.productData['description'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                        SizedBox(height: 32),
                        _buildRatingStatistics(),
                        _buildReviewsList(),
                        if (_isEditMode)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: !_isEditMode
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
              child: Icon(Icons.edit),
              backgroundColor: Colors.redAccent,
            )
          : null,
    );
  }
}