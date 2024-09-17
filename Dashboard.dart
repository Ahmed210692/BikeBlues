import 'package:bikeblues/AdminPanel/VendorsList.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

// Function to fetch vendors from Firestore
Future<List<Map<String, dynamic>>> fetchVendors() async {
  final vendorSnapshot = await FirebaseFirestore.instance.collection('vendors').get();
  return vendorSnapshot.docs.map((doc) => doc.data()).toList();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final screenheight = MediaQuery.of(context).size.height;
    final screenwidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'DASHBOARD',
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
            ),
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.menu_open_outlined,
              size: 40,
              color: Colors.black,
            ),
          ),
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

            // Number of vendors
            final int totalVendors = snapshot.data!.length;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: (){
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VendorsList()));
                    },
                    child: Container(
                      height: screenheight * 0.3,
                      width: screenwidth * 0.5,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(

                            child: Expanded(child: Image.asset('assets/images/vendor-icon-vector.jpg'),
                            ),
                            radius: 30,

                          ),
                          SizedBox(height: screenheight * 0.04,),
                          Text(
                             '$totalVendors',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent
                            ),
                          ),
                          SizedBox(height: screenheight * 0.04,),
                          Text('Total Vendors', style: TextStyle(fontSize: 20, color: Colors.grey),)
                        ],
                      ),
                    ),
                  ),

                ),
                SizedBox(height: screenheight * 0.1,),
                Center(
                  child: Container(
                    height: screenheight * 0.3,
                    width: screenwidth * 0.5,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(

                          child: Expanded(child: Image.asset('assets/images/user icon.png'),
                          ),
                          radius: 30,

                        ),
                        SizedBox(height: screenheight * 0.04,),
                        Text(
                          ' $totalVendors',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrangeAccent,
                          ),

                        ),
                        SizedBox(height: screenheight * 0.04,),
                        Text('Total Users', style: TextStyle(fontSize: 20, color: Colors.grey),)
                      ],
                    ),
                  ),

                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
