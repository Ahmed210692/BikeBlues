import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    return productList.docs.map((doc) => doc.data()).toList();
  }

  // Method to fetch vendor details
  Future<Map<String, dynamic>> fetchVendorDetails() async {
    final vendorDoc = await FirebaseFirestore.instance
        .collection('vendors')
        .doc(widget.vendorId)
        .get();
    return vendorDoc.data()!;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
          title: Text(
            'Products',
            style: TextStyle(fontSize: 30, color: Colors.black),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        drawer: FutureBuilder<Map<String, dynamic>>(
          future: fetchVendorDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Drawer(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Drawer(
                child: Center(
                  child: Text('Error fetching vendor details'),
                ),
              );
            }

            final vendorData = snapshot.data!;

            return Drawer(

              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blueGrey,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: vendorData['storeImage'] != null
                              ? NetworkImage(vendorData['storeImage'])
                              : null,
                          child: vendorData['storeImage'] == null
                              ? Icon(Icons.store, size: 50)
                              : null,
                        ),
                        SizedBox(height: 10),
                        Text(
                          vendorData['vendorName'] ?? 'No Vendor Name',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.store),
                    title: Text('Shop Name'),
                    subtitle: Text(vendorData['shopName'] ?? 'No Shop Name'),
                  ),
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text('Email'),
                    subtitle: Text(vendorData['email'] ?? 'No Email'),
                  ),
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text('Address'),
                    subtitle: Text(vendorData['address'] ?? 'No Address'),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text('Phone Number'),
                    subtitle: Text(vendorData['phoneNumber'] ?? 'No Phone Number'),
                  ),
                  ListTile(
                    leading: Icon(Icons.lock),
                    title: Text('Password'),
                    subtitle: Text(vendorData['password'] ?? 'No Password'),
                  ),
                ],
              ),
            );
          },
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchVendorProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error fetching products'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No products found for this vendor'));
            }

            final productList = snapshot.data!;

            return ListView.builder(
              itemCount: productList.length,
              itemBuilder: (context, index) {
                final product = productList[index];
                final imageUrl = product['imageUrl'] ?? ''; // Ensure this field exists

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.fill,
                          )
                              : Icon(Icons.image, size: 50),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? 'No Product Name',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Price: ${product['price'] ?? 'No Price'}',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
