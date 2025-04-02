import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class VendorsProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final String productId;

  const VendorsProductDetailScreen({
    super.key,
    required this.product,
    required this.productId,
  });

  Widget _buildRatingStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF53DDA3)),
            ),
          );
        }

        // Initialize rating distribution map and total rating
        Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        double totalRating = 0;
        int totalReviews = snapshot.data!.docs.length;

        // Calculate rating distribution and total
        snapshot.data!.docs.forEach((doc) {
          final dynamic ratingValue = (doc.data() as Map<String, dynamic>)['rating'];
          double rating;

          if (ratingValue is int) {
            rating = ratingValue.toDouble();
          } else if (ratingValue is double) {
            rating = ratingValue;
          } else {
            rating = 0.0;
          }

          totalRating += rating;
          ratingDistribution[rating.round()] =
              (ratingDistribution[rating.round()] ?? 0) + 1;
        });

        // Calculate average rating
        final averageRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(40, 40, 40, 1),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with average rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF4E9CD4), Color(0xFF53DDA3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Customer Reviews',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on $totalReviews reviews',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // Average rating display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(50, 50, 50, 1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF53DDA3).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF53DDA3),
                          ),
                        ),
                        RatingBarIndicator(
                          rating: averageRating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Color(0xFF53DDA3),
                          ),
                          itemCount: 5,
                          itemSize: 16.0,
                          unratedColor: const Color(0xFF53DDA3).withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Rating distribution bars
              ...List.generate(5, (index) {
                final starRating = 5 - index;
                final count = ratingDistribution[starRating] ?? 0;
                return _buildRatingBar(starRating, count, totalReviews);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Build individual rating distribution bar
  Widget _buildRatingBar(int stars, int count, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text(
              '$stars ★',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: const Color.fromRGBO(50, 50, 50, 1),
                  ),
                  FractionallySizedBox(
                    widthFactor: total > 0 ? count / total : 0,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4E9CD4), Color(0xFF53DDA3)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Build the reviews list
  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF53DDA3)),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(40, 40, 40, 1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                'No reviews yet. Be the first to review!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final reviewData =
            snapshot.data!.docs[index].data() as Map<String, dynamic>;

            // Handle rating type conversion
            final dynamic ratingValue = reviewData['rating'];
            double rating;
            if (ratingValue is int) {
              rating = ratingValue.toDouble();
            } else if (ratingValue is double) {
              rating = ratingValue;
            } else {
              rating = 0.0;
            }

            // Format timestamp
            String formattedDate = '';
            if (reviewData['timestamp'] != null) {
              final timestamp = (reviewData['timestamp'] as Timestamp).toDate();
              formattedDate = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
            }

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(40, 40, 40, 1),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reviewData['userName'] ?? 'Anonymous',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (formattedDate.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      RatingBarIndicator(
                        rating: rating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Color(0xFF53DDA3),
                        ),
                        itemCount: 5,
                        itemSize: 16.0,
                        unratedColor: const Color(0xFF53DDA3).withOpacity(0.2),
                      ),
                    ],
                  ),
                  if (reviewData['review'] != null &&
                      reviewData['review'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      reviewData['review'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageUrl = product['imageUrl'] ?? '';
    final title = product['name'] ?? 'No Product Name';
    final price = product['price'] ?? 'No Price';
    final description = product['description'] ?? 'No Description';

    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
        title: Text(
          title,
          style: TextStyle(
            foreground: Paint()
              ..shader = LinearGradient(
                colors: const [Color(0xFF4E9CD4), Color(0xFF53DDA3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(
                Rect.fromLTWH(0, 0, screenWidth * 0.5, screenHeight * 0.05),
              ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Gradient Border
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4E9CD4), Color(0xFF53DDA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4E9CD4).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey[900],
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                ),
              ),
            ),

            // Product Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(40, 40, 40, 1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF53DDA3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rs. $price',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF53DDA3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Ratings and Reviews Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildRatingStatistics(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildReviewsList(),
            ),
          ],
        ),
      ),
    );
  }
}