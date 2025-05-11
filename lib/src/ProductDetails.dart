import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../chat/chatScreen.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productId;

  const ProductDetails({
    super.key,
    required this.product,
    required this.productId,
  });

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  String? _vendorId;
  String? _vendorName;
  bool _isFavorite = false;
  final TextEditingController _reviewController = TextEditingController();
  double _currentRating = 0;

  @override
  void initState() {
    super.initState();
    _fetchVendorDetails();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _initiateChat() async {
    final currentUser  = FirebaseAuth.instance.currentUser ;
    if (currentUser  == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to start a chat')),
      );
      return;
    }

    // Get user details
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser .uid)
        .get();

    // Get vendor details (assuming you have the vendorId)
    String vendorId = widget.product['vendorId'];
    DocumentSnapshot vendorDoc = await FirebaseFirestore.instance
        .collection('vendors') // Assuming you have a 'vendors' collection
        .doc(vendorId)
        .get();

    String vendorName = vendorDoc['vendorName'] ?? 'Vendor'; // Get vendor name

    // Check if chat room already exists
    QuerySnapshot existingChatRooms = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('userId', isEqualTo: currentUser .uid)
        .where('vendorId', isEqualTo: vendorId)
        .limit(1)
        .get();

    String chatRoomId;
    if (existingChatRooms.docs.isNotEmpty) {
      // Use existing chat room
      chatRoomId = existingChatRooms.docs.first.id;
    } else {
      // Create new chat room
      DocumentReference chatRoomRef = FirebaseFirestore.instance
          .collection('chatRooms')
          .doc();

      chatRoomId = chatRoomRef.id;

      await chatRoomRef.set({
        'userId': currentUser .uid,
        'vendorId': vendorId,
        'userName': userDoc['name'] ?? 'User ',
        'vendorName': vendorName, // Use the retrieved vendor name
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessage': 'Chat started',
      });
    }

    // Navigate to the chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: chatRoomId,
          otherUserId: vendorId,
          otherUserName: vendorName, // Pass the vendor name to the chat screen
        ),
      ),
    );
  }

  Future<void> _fetchVendorDetails() async {
    try {
      DocumentSnapshot vendorSnapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.product['vendorId'])
          .get();

      if (vendorSnapshot.exists) {
        setState(() {
          _vendorId = vendorSnapshot.id;
          _vendorName = vendorSnapshot['name'] ?? 'Unknown Vendor';
        });
      }
    } catch (e) {
      print('Error fetching vendor details: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favoriteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.productId)
          .get();

      setState(() {
        _isFavorite = favoriteDoc.exists;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favoriteRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.productId);

      if (_isFavorite) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set(widget.product);
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite
              ? 'Added to Favorites'
              : 'Removed from Favorites'
          ),
        ),
      );
    }
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    String userName = userDoc['name'] ?? 'Anonymous';
    if (user != null && _reviewController.text.isNotEmpty && _currentRating > 0) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .add({
        'userId': user.uid,
        'userName': userName,
        'rating': _currentRating.toDouble(),
        'review': _reviewController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _reviewController.clear();
      setState(() {
        _currentRating = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully!')),
      );
    }
  }

  Widget _buildRatingStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        double totalRating = 0;

        snapshot.data!.docs.forEach((doc) {
          final rating = (doc.data() as Map<String, dynamic>)['rating'] as num;
          totalRating += rating;
          ratingDistribution[rating.toInt()] =
              (ratingDistribution[rating.toInt()] ?? 0) + 1;
        });

        final totalReviews = snapshot.data!.docs.length;
        final averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RatingBarIndicator(
                        rating: averageRating.toDouble() ,
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 24.0,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$totalReviews Reviews',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...List.generate(5, (index) {
                final starRating = 5 - index;
                final count = ratingDistribution[starRating] ?? 0;
                return _buildRatingBar(starRating, count, totalReviews);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$stars★',
              style: TextStyle(color: Colors.amber),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? count / total : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 8,
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
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
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Customer Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              ...snapshot.data!.docs.map((doc) {
                final reviewData = doc.data() as Map<String, dynamic>;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue,
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              RatingBarIndicator(
                                rating: (reviewData['rating'] as num).toDouble(),
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
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write a Review',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: RatingBar.builder(
              initialRating: _currentRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _currentRating = rating;
                });
              },
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            decoration: InputDecoration(
              hintText: 'Share your experience with this product',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Submit Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: widget.productId,
                    child: Image.network(
                      widget.product['imageUrl'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.product['name'],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rs. ${widget.product['price']}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.product['description'] ?? 'No description available.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRatingStatistics(),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _buildReviewsList(),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: _buildReviewInput(),
                ),
                SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: ElevatedButton(
                  onPressed: _initiateChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message, size: 22, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Contact Seller',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 28,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
