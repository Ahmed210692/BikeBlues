import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'VendorsProductsDetail.dart';

class VendorsProducts extends StatefulWidget {
  final String vendorId;

  const VendorsProducts({super.key, required this.vendorId});

  @override
  State<VendorsProducts> createState() => _VendorsProductsState();
}

class _VendorsProductsState extends State<VendorsProducts> {
  // Method to fetch products for a specific vendor
  Future<List<Map<String, dynamic>>> fetchVendorProducts() async {
    final productList = await FirebaseFirestore.instance
        .collection('products')
        .where('vendorId', isEqualTo: widget.vendorId)
        .get();

    // Convert QueryDocumentSnapshot to Map with document ID
    return productList.docs.map((doc) {
      Map<String, dynamic> data = doc.data();
      data['id'] = doc.id; // Add document ID to the data
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Products',
            style: TextStyle(
              fontSize: 30,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: const [Color(0xFF4E9CD4), Color(0xFF53DDA3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(
                  Rect.fromLTWH(0, 0, screenWidth * 0.5, screenHeight * 0.05),
                ),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchVendorProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error fetching products'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No products found for this vendor'));
            }

            final productList = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two items per row
                    childAspectRatio: 0.8, // Adjust for image and text alignment
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: productList.length,
                  itemBuilder: (context, index) {
                    final product = productList[index];
                    final imageUrl = product['imageUrl'] ?? '';
                    final productId = product['id'];// Ensure this field exists

                    return GestureDetector(
                      onTap: () {
                        // Navigate to product detail screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VendorsProductDetailScreen(
                              product: product,
                              productId: productId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(86, 86, 86, 1),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Product Image
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                ),
                                child: imageUrl.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                                    : const Icon(Icons.image, size: 50),
                              ),
                            ),
                            // Product Title
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                product['name'] ?? 'No Product Name',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
