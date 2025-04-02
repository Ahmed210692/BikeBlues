import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Vendorsproduct.dart';

class VendorsList extends StatefulWidget {
  const VendorsList({super.key});

  @override
  State<VendorsList> createState() => _VendorsListState();
}

Future<List<Map<String, dynamic>>> fetchVendors() async {
  final vendorsList = await FirebaseFirestore.instance.collection('vendors').get();
  return vendorsList.docs.map((doc) => doc.data()).toList();
}

class _VendorsListState extends State<VendorsList> {
  // Method to delete a vendor
  Future<void> deleteVendor(String vendorId) async {
    try {
      await FirebaseFirestore.instance.collection('vendors').doc(vendorId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vendor deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting vendor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromRGBO(30, 30, 30, 1),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Total Vendors',
            style: TextStyle(
              fontSize: 30,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: <Color>[
                    Color(0xFF4E9CD4),
                    Color(0xFF53DDA3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(
                  Rect.fromLTWH(0, 0, screenWidth * 0.5, screenHeight * 0.05),
                ),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color.fromRGBO(30, 30, 30, 1),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchVendors(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error fetching data'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No vendors found'));
              }

              final vendorList = snapshot.data!;
              final int totalVendors = vendorList.length;

              return Column(
                children: [
                  // Display total number of vendors
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      ' $totalVendors',
                      style: TextStyle(
                        fontSize: 30,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: <Color>[
                              Color(0xFF4E9CD4),
                              Color(0xFF53DDA3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(
                            Rect.fromLTWH(0, 0, screenWidth * 0.5, screenHeight * 0.05),
                          ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: vendorList.length,
                      itemBuilder: (context, index) {
                        final vendor = vendorList[index];
                        final vendorId = vendor['id']; // Ensure you have a unique identifier field for the vendor
                        return Card(
                          color: Color.fromRGBO(217, 217, 217, 1),
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(vendor['vendorName'] ?? 'No Name', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                            leading: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey,
                              child: Image.network(vendor['storeImage'] ?? '', fit: BoxFit.fill,),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Shop: ${vendor['shopName'] ?? 'No Shop Name'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                Text('Email: ${vendor['email'] ?? 'No Email'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              //  Text('Password: ${vendor['password'] ?? 'No Password'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                Text('Contact: ${vendor['phoneNumber'] ?? 'No PhoneNumber'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                Text('Address: ${vendor['address'] ?? 'No Address'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VendorsProducts(vendorId: vendorId),
                                ),
                              );
                            },
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Confirm Delete'),
                                    content: Text('Are you sure you want to delete this vendor?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          deleteVendor(vendorId);
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
