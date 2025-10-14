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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedCategory = 'All'; // Default to show all categories
  final List<String> _categories = ['All', 'Engine', 'Electrical', 'Chassis', 'Accessories'];


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

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: _selectedCategory == category,
              selectedColor: Color(0xFF53DDA3),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'All';
                });
              },
              labelStyle: TextStyle(
                color: _selectedCategory == category ? Colors.black : Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildHomeScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_vendor?.vendorName ?? 'N/A'}!',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: _vendor?.storeImage != null
                          ? NetworkImage(_vendor!.storeImage!) as ImageProvider
                          : const AssetImage('assets/default_profile.png'),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF53DDA3)),
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
                cursorColor: Color(0xFF53DDA3),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.02,),
            _buildCategoryChips(),
            SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('vendorId', isEqualTo: _vendor?.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF53DDA3)),
                      ),
                    );
                  }

                  var products = snapshot.data!.docs.where((product) {
                    String productName = product['name']?.toLowerCase() ?? '';
                    bool matchesSearch = productName.contains(searchQuery);
                    bool matchesCategory = _selectedCategory == 'All' ||
                        product['category'] == _selectedCategory;
                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, 
                            size: 64, 
                            color: Colors.white24
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8, // Adjusted from 0.75 to 0.8
                    ),
                    padding: EdgeInsets.only(bottom: 90),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index].data() as Map<String, dynamic>;
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
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(
                                  product['imageUrl'],
                                  width: double.infinity,
                                  height: screenHeight * 0.13, // Reduced from 140 to 130
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0), // Reduced padding from 12 to 8
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      style: TextStyle(
                                        fontSize: 14, // Reduced from 16 to 14
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                   // SizedBox(height: screenHeight * 0.001), // Reduced from 8 to 4
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'RS ${product['price']}',
                                          style: TextStyle(
                                            fontSize: 12, // Reduced from 16 to 14
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF53DDA3),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline,
                                              color: Colors.red[300],
                                              size: 20), // Reduced icon size
                                          padding: EdgeInsets.zero, // Remove padding
                                          constraints: BoxConstraints(), // Remove constraints
                                          onPressed: () async {
                                            bool confirmDelete =
                                            await _showDeleteConfirmationDialog(
                                                context);
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

  @override
  Widget build(BuildContext context) {
    final Vendor? vendor = ModalRoute.of(context)?.settings.arguments as Vendor?;

    return Theme(
      data: darkTheme,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Color.fromRGBO(30, 30, 30, 1),
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
                          Navigator.of(context).push(
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
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
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
                      icon: Icon(
                        Icons.home_rounded,
                        size: 28,
                        color: _selectedIndex == 0 ? Color(0xFF53DDA3) : Colors.white
                      ),
                      onPressed: () => _onItemTapped(0),
                    ),
                    SizedBox(width: 40),
                    IconButton(
                      icon: Icon(
                        Icons.chat_rounded,
                        size: 28,
                        color: _selectedIndex == 1 ? Color(0xFF53DDA3) : Colors.white
                      ),
                      onPressed: () => _onItemTapped(1),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: MediaQuery.of(context).size.width / 2 - 32,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4E9CD4), Color(0xFF53DDA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF53DDA3).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductScreen()),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Icon(Icons.add, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}