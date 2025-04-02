import 'package:bikeblues/AdminPanel/Dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'Vendorsproduct.dart';

class UsersList extends StatefulWidget {
  const UsersList({super.key});

  @override
  State<UsersList> createState() => _UsersListState();
}

Future<List<Map<String, dynamic>>> fetchUsers() async {
  final usersList = await FirebaseFirestore.instance.collection('users').get();
  return usersList.docs.map((doc) => doc.data()).toList();
}

class _UsersListState extends State<UsersList> {
  // Method to delete a vendor
  Future<void> deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting User: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromRGBO(30, 30, 30, 1),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('USERS', style: TextStyle(fontSize: 30, foreground: Paint()
            ..shader = LinearGradient(
              colors: <Color>[
                Color(0xFF4E9CD4),
                Color(0xFF53DDA3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(
              Rect.fromLTWH(0, 0, screenWidth * 0.5, screenHeight * 0.05),
            ),)),
          centerTitle: true,
          backgroundColor: Color.fromRGBO(30, 30, 30, 1),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error fetching data'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No users found'));
            }

            final userList = snapshot.data!;

            return ListView.builder(
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final user = userList[index];
                final userId = user['id']; // Ensure you have a unique identifier field for the vendor

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    //title: Text(user['vendorName'] ?? 'No Name'),
                   // leading: Image.network(user['storeImage']?? '', fit: BoxFit.fill,),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: ${user['name'] ?? 'No Name'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
                        Text('Email: ${user['email'] ?? 'No Shop Name'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                       // Text('Password: ${user['password'] ?? 'No Email'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        Text('Contact: ${user['phoneNumber'] ?? 'No Shop Name'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        Text('Address: ${user['address'] ?? 'No Shop Name'}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Confirm Delete'),
                            content: Text('Are you sure you want to delete this User?'),
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
                                  deleteUser(userId);
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
