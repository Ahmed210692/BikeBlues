import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/Vendor_model.dart';
import 'ProductScreen.dart';
import 'VendorProdDetail.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
            ),
          ],
        );
      },
    )) ??
        false; // return false if the dialog is dismissed
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Vendor? vendor = ModalRoute.of(context)?.settings.arguments as Vendor?;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(30, 30, 30, 1),
        title: Text(
          vendor?.shopName ?? 'N/A',
          style: const TextStyle(
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        elevation: 8,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductScreen()),
              );
            },
            icon: const Icon(
              Icons.add_circle_rounded,
              size: 30,
            ),
          )
        ],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: CircleAvatar(
                radius: 30,
                backgroundImage: vendor?.storeImage != null
                    ? NetworkImage(vendor!.storeImage!) as ImageProvider
                    : const AssetImage('assets/default_profile.png'),
                child: vendor?.storeImage == null ? const Icon(Icons.person) : null,
              ),
            );
          },
        ),
      ),
      drawer: Drawer(
        width: screenWidth * 0.7,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(80),
            bottomRight: Radius.circular(80),
          ),
        ),
        elevation: 12,
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
            CircleAvatar(

                backgroundImage: vendor?.storeImage != null
                    ? NetworkImage(vendor!.storeImage!) as ImageProvider
                    : const AssetImage('assets/default_profile.png'),
              radius: 40,
               ),
                  SizedBox(height: screenHeight * 0.02,),
                  Text(vendor?.vendorName ?? 'Vendor Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),

                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4E9CD4),
                          Color(0xFF53DDA3), // #51483A
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border(
                        right: BorderSide(
                          color: Color(0xFF53DDA3), // rgba(255, 170, 0, 1)
                          width: 4,
                        ),
                        top: BorderSide(
                          color: Color(0xFF4E9CD4), // rgba(255, 170, 0, 1)
                          width: 4,
                        ),

                      ),
                    ),
                    height: screenHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.person_outlined,
                              color: Colors.white,
                              size: screenHeight * 0.04,
                            ),
                            title: Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenHeight * 0.02,
                              ),
                            ),
                            //onTap: _showPrivacyPolicyDialog,
                          ),

                          SizedBox(height: screenHeight * 0.02),
                          ListTile(
                            leading: Icon(
                              Icons.share,
                              color: Colors.white,
                              size: screenHeight * 0.04,
                            ),
                            title: Text(
                              'Share App',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenHeight * 0.02,
                              ),
                            ),
                            onTap: () {
                              // Share.share(
                              //   translation[selectedTranslation]?['Check out the Six Kalimas app!']?? '',
                              //   subject: translation[selectedTranslation]?['Six Kalimas']?? '',
                              // );
                            },
                          ),

                          SizedBox(height: screenHeight * 0.02),
                          ListTile(
                            leading: Icon(
                              Icons.login_outlined,
                              color: Colors.white,
                              size: screenHeight * 0.04,
                            ),
                            title: Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenHeight * 0.02,
                              ),
                            ),
                            //onTap: _showExitDialog,
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: screenHeight * 0.04,
              width: screenWidth * 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Welcome ${vendor?.vendorName ?? 'N/A'}!',
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.06),
            const Text(
              'All Products',
              style: TextStyle(fontSize: 25, color: Colors.yellow),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('vendorId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong'));
                  }

                  final products = snapshot.data?.docs ?? [];

                  if (products.isEmpty) {
                    return const Center(child: Text('No products available.'));
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2 / 3,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index].data() as Map<String, dynamic>;
                      final productId = products[index].id; // Get the product ID

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(productData: product, productId: productId,),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Stack(
                                  children: [
                                    Image.network(
                                      product['imageUrl'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'RS: ${product['price']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                          Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              bool confirmDelete = await _showDeleteConfirmationDialog(context);
                                              if (confirmDelete) {
                                                await _deleteProduct(productId);
                                              }
                                            },
                                          ),
                                        ],
                                      ),

                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
