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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('VENDORS', style: TextStyle(fontSize: 30, color: Colors.black)),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
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

            return ListView.builder(
              itemCount: vendorList.length,
              itemBuilder: (context, index) {
                final vendor = vendorList[index];
                final vendorId = vendor['id']; // Ensure you have a unique identifier field for the vendor

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(vendor['vendorName'] ?? 'No Name'),
                    leading: Image.network(vendor['storeImage']?? '', fit: BoxFit.fill,),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shop: ${vendor['shopName'] ?? 'No Shop Name'}'),
                        Text('Email: ${vendor['email'] ?? 'No Email'}'),
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
            );
          },
        ),
      ),
    );
  }
}
