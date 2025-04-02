import 'package:bikeblues/Authentication/SignInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../model/Vendor_model.dart';
import 'ProductScreen.dart';
import 'VendorChat.dart';
import 'VendorProdDetail.dart';
import 'VendorProfileScreen.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends State<VendorDashboard> {
  String searchQuery = '';
  int _selectedIndex = 0;
  late Vendor? _vendor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vendor = ModalRoute.of(context)?.settings.arguments as Vendor?;
  }

  List<Widget> _widgetOptions() {
    return [
      _buildHomeScreen(), // Home screen with products
      VendorChatListScreen(vendor: _vendor), // Chat list screen
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Dark theme configuration
  final darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF4E9CD4),
      secondary: Color(0xFF53DDA3),
      surface: Color.fromRGBO(45, 45, 45, 1),
      background: Color.fromRGBO(30, 30, 30, 1),
    ),
    cardTheme: CardTheme(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Color.fromRGBO(45, 45, 45, 1),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content:
          const Text('Are you sure you want to delete this product?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    )) ??
        false;
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    )) ??
        false;
  }

  Widget _buildHomeScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
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
                    'Welcome ${_vendor?.vendorName ?? 'N/A'}!',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Color(0xFF4E9CD4).withOpacity(0.5),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search, color: Color(0xFF53DDA3)),
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(color: Color(0xFF4E9CD4), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(color: Colors.white24, width: 1),
              ),
            ),
            style: TextStyle(color: Colors.white),
            cursorColor: Color(0xFF53DDA3),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('vendorId', isEqualTo: _vendor?.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF53DDA3)),
                    ),
                  );
                }

                var products = snapshot.data!.docs.where((product) {
                  String productName = product['name']?.toLowerCase() ?? '';
                  return productName.contains(searchQuery);
                }).toList();

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product =
                    products[index].data() as Map<String, dynamic>;
                    final productId = products[index].id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              productData: product,
                              productId: productId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Image.network(
                                      product['imageUrl'],
                                      width: double.infinity,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 50,
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
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'RS: ${product['price']}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF53DDA3),
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                              Colors.red.withOpacity(0.2),
                                            ),
                                            child: IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                bool confirmDelete =
                                                await _showDeleteConfirmationDialog(
                                                    context);
                                                if (confirmDelete) {
                                                  await _deleteProduct(
                                                      productId);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final Vendor? vendor =
    ModalRoute.of(context)?.settings.arguments as Vendor?;

    return Theme(
      data: darkTheme,
      child: Scaffold(
        backgroundColor: Color.fromRGBO(30, 30, 30, 1),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            vendor?.shopName ?? 'N/A',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [Color(0xFF4E9CD4), Color(0xFF53DDA3)],
                ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
            ),
          ),
          centerTitle: true,
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
                  child: vendor?.storeImage == null
                      ? const Icon(Icons.person)
                      : null,
                ),
              );
            },
          ),
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4E9CD4).withOpacity(0.9),
                  Color(0xFF53DDA3).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
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
                      SizedBox(height: 10),
                      Text(
                        vendor?.vendorName ?? 'Vendor Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        leading:
                        Icon(Icons.person, size: 30, color: Colors.white),
                        title: Text('Profile',
                            style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator .of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    VendorProfileScreen(vendor: vendor!)),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.share, color: Colors.white),
                        title: Text('Share App',
                            style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Share.share('Check out this BikeBlues app!',
                              subject: 'BikeBlues');
                        },
                      ),
                      ListTile(
                        leading:
                        Icon(Icons.login_outlined, color: Colors.white),
                        title: Text('Log Out',
                            style: TextStyle(color: Colors.white)),
                        onTap: () async {
                          bool confirmLogout =
                          await _showLogoutConfirmationDialog(context);
                          if (confirmLogout) {
                            await FirebaseAuth.instance.signOut();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => UnifiedLoginScreen()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            _widgetOptions().elementAt(_selectedIndex),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(30, 30, 30, 1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.home, color: _selectedIndex == 0 ? Color(0xFF53DDA3) : Colors.white),
                      onPressed: () => _onItemTapped(0),
                    ),
                    SizedBox(width: 40), // Space for the floating button
                    IconButton(
                      icon: Icon(Icons.chat, color: _selectedIndex == 1 ? Color(0xFF53DDA3) : Colors.white),
                      onPressed: () => _onItemTapped(1),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width / 2 - 30,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProductScreen()),
                  );
                },
                backgroundColor: Color(0xFF53DDA3),
                child: Icon(Icons.add, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}