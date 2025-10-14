import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'FavoriteScreen.dart';
import 'ProductDetails.dart';
import 'UserChatListScreen.dart';
import 'UserProfileScreen.dart';

class PurchaseParts extends StatefulWidget {
  const PurchaseParts({super.key});

  @override
  State<PurchaseParts> createState() => _PurchasePartsState();
}

class _PurchasePartsState extends State<PurchaseParts> with SingleTickerProviderStateMixin {
  String? username;
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Engine', 'Electrical', 'Chassis', 'Accessories'];

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    super.initState();
    _setupScrollController();
    _fetchUserDetails();
    _animationController.forward();
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      setState(() {
        _showBackToTop = _scrollController.offset > 200;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        username = userDoc['name'];
      });
    }
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;

    if (index == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserChatListScreen()),
      );
      setState(() => _selectedIndex = 0);
      return;
    }

    if (index == 2) {
      final userData = await _fetchUserData();
      if (userData != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen(userData: userData)),
        );
      }
      setState(() => _selectedIndex = 0);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return userDoc.data();
    }
    return null;
  }

  void _navigateToFavorites() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FavoritesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _animationController.reset();
      _animationController.forward();
    });
  }

  // Helper method to get responsive dimensions
  double _getResponsiveWidth(double w, double percentage) {
    return w * percentage;
  }

  double _getResponsiveHeight(double h, double percentage) {
    return h * percentage;
  }

  // Helper method to get responsive font size
  double _getResponsiveFontSize(double w, double baseSize) {
    // Scale font size based on screen width
    if (w < 360) return baseSize * 0.9;
    if (w > 400) return baseSize * 1.1;
    return baseSize;
  }

  // Helper method to get responsive padding
  EdgeInsets _getResponsivePadding(double w, double h) {
    double horizontalPadding = w < 360 ? 12 : (w > 400 ? 24 : 16);
    double verticalPadding = h < 700 ? 8 : (h > 800 ? 20 : 16);
    return EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
  }

  // Helper method to determine grid count based on screen size
  int _getGridCrossAxisCount(double w) {
    if (w < 360) return 1; // Very small screens
    if (w > 500) return 3; // Large screens (tablets in portrait)
    return 2; // Standard mobile screens
  }

  // Helper method to get card height based on screen size
  double _getCardHeight(double w, double h) {
    if (w < 360) return h * 0.35; // Smaller cards for small screens
    if (w > 400) return h * 0.28;  // Medium cards for larger screens
    return h * 0.32; // Standard height
  }

  Widget _buildCategoryChips(double w, double h) {
    return SizedBox(
      height: _getResponsiveHeight(h, 0.06), // 6% of screen height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Padding(
            padding: EdgeInsets.only(right: _getResponsiveWidth(w, 0.02)), // 2% of screen width
            child: ChoiceChip(
              label: Text(
                category,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(w, 14),
                ),
              ),
              selected: _selectedCategory == category,
              selectedColor: Theme.of(context).primaryColor,
              onSelected: (selected) => _changeCategory(category),
              labelStyle: TextStyle(
                color: _selectedCategory == category ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: _getResponsiveFontSize(w, 14),
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.05)), // 5% of screen width
                side: BorderSide(
                  color: _selectedCategory == category
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingShimmer(double w, double h) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(w),
          crossAxisSpacing: _getResponsiveWidth(w, 0.04), // 4% of screen width
          mainAxisSpacing: _getResponsiveHeight(h, 0.02), // 2% of screen height
          childAspectRatio: w < 360 ? 0.8 : (w > 400 ? 0.75 : 0.7),
        ),
        itemCount: 6,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.05)), // 5% of screen width
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          bottomNavigationBar: Container(
            margin: EdgeInsets.symmetric(
              horizontal: _getResponsiveWidth(w, 0.04), // 15% of screen width
              vertical: _getResponsiveHeight(h, 0.01),   // 1% of screen height
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.06)), // 6% of screen width
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.06)),
              child: BottomNavigationBar(
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(_getResponsiveWidth(w, 0.02)), // 2% of screen width
                      decoration: BoxDecoration(
                        color: _selectedIndex == 0 ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.03)), // 3% of screen width
                      ),
                      child: Icon(
                        Icons.home_outlined,
                        size: _getResponsiveWidth(w, 0.06), // 6% of screen width
                      ),
                    ),
                    activeIcon: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(_getResponsiveWidth(w, 0.02)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.03)),
                      ),
                      child: Icon(
                        Icons.home,
                        size: _getResponsiveWidth(w, 0.06),
                      ),
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(_getResponsiveWidth(w, 0.02)),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1 ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.03)),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: _getResponsiveWidth(w, 0.06),
                      ),
                    ),
                    activeIcon: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(_getResponsiveWidth(w, 0.02)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.03)),
                      ),
                      child: Icon(
                        Icons.chat_bubble,
                        size: _getResponsiveWidth(w, 0.06),
                      ),
                    ),
                    label: 'Chats',
                  ),
                  BottomNavigationBarItem(
                    icon: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(_getResponsiveWidth(w, 0.02)),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 2 ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.03)),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: _getResponsiveWidth(w, 0.06),
                      ),
                    ),
                    activeIcon: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(_getResponsiveWidth(w, 0.02)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.03)),
                      ),
                      child: Icon(
                        Icons.person,
                        size: _getResponsiveWidth(w, 0.06),
                      ),
                    ),
                    label: 'Profile',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Colors.grey[600],
                selectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: _getResponsiveFontSize(w, 12),
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: _getResponsiveFontSize(w, 12),
                ),
                onTap: _onItemTapped,
                elevation: 0,
                backgroundColor: Colors.transparent,
                type: BottomNavigationBarType.fixed,
                iconSize: _getResponsiveWidth(w, 0.06),
                showSelectedLabels: true,
                showUnselectedLabels: true,
              ),
            ),
          ),
          floatingActionButton: _showBackToTop
              ? FloatingActionButton.extended(
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            icon: Icon(
              Icons.arrow_upward,
              color: Colors.white,
              size: _getResponsiveWidth(w, 0.05), // 5% of screen width
            ),
            label: Text(
              'Top',
              style: TextStyle(
                color: Colors.white,
                fontSize: _getResponsiveFontSize(w, 14),
              ),
            ),
            backgroundColor: Colors.blue[700],
          )
              : null,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: _getResponsivePadding(w, h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: _getResponsiveHeight(h, 0.02)), // 2% of screen height
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Products',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontSize: _getResponsiveFontSize(w, 26),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.03)), // 3% of screen width
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.favorite,
                                  color: Colors.red[400],
                                  size: _getResponsiveWidth(w, 0.06), // 6% of screen width
                                ),
                                onPressed: _navigateToFavorites,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _getResponsiveHeight(h, 0.025)), // 2.5% of screen height

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.blue[700],
                              size: _getResponsiveWidth(w, 0.06), // 6% of screen width
                            ),
                            hintText: 'Search Products...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: _getResponsiveFontSize(w, 16),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.05)), // 5% of screen width
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.05)),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.05)),
                              borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveWidth(w, 0.04), // 4% of screen width
                              vertical: _getResponsiveHeight(h, 0.02),   // 2% of screen height
                            ),
                          ),
                          style: TextStyle(fontSize: _getResponsiveFontSize(w, 16)),
                        ),
                      ),
                      SizedBox(height: _getResponsiveHeight(h, 0.025)),

                      // Category Chips
                      _buildCategoryChips(w, h),
                      SizedBox(height: _getResponsiveHeight(h, 0.025)),

                      // Section Title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _selectedCategory == 'All' ? 'All Products' : _selectedCategory,
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(w, 22),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _getResponsiveHeight(h, 0.025)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: _getResponsivePadding(w, h),
                sliver: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(child: _buildLoadingShimmer(w, h));
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: _getResponsiveWidth(w, 0.15), // 15% of screen width
                                color: Colors.red[400],
                              ),
                              SizedBox(height: _getResponsiveHeight(h, 0.02)),
                              Text(
                                'Something went wrong',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(w, 16),
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final products = snapshot.data?.docs ?? [];
                    final filteredProducts = products.where((doc) {
                      final productData = doc.data() as Map<String, dynamic>;
                      final productName = productData['name']?.toString().toLowerCase() ?? '';
                      final productCategory = productData['category']?.toString() ?? 'Engine';

                      final matchesSearch = productName.contains(searchQuery);
                      final matchesCategory = _selectedCategory == 'All' ||
                          productCategory == _selectedCategory;

                      return matchesSearch && matchesCategory;
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: _getResponsiveWidth(w, 0.15), // 15% of screen width
                                color: Colors.grey,
                              ),
                              SizedBox(height: _getResponsiveHeight(h, 0.02)),
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(w, 16),
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getGridCrossAxisCount(w),
                        crossAxisSpacing: _getResponsiveWidth(w, 0.04), // 4% of screen width
                        mainAxisSpacing: _getResponsiveHeight(h, 0.02),  // 2% of screen height
                        childAspectRatio: w < 360 ? 0.8 : (w > 400 ? 0.75 : 0.7),
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final product = filteredProducts[index].data() as Map<String, dynamic>;
                          final productId = filteredProducts[index].id;

                          return Hero(
                            tag: 'product-$productId',
                            child: Material(
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetails(
                                        product: product,
                                        productId: productId,
                                      ),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.05)), // 5% of screen width
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(_getResponsiveWidth(w, 0.05)), // 5% of screen width
                                        ),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              product['imageUrl'],
                                              height: _getCardHeight(w, h) * 0.65, // 65% of card height for image
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, progress) {
                                                if (progress == null) return child;
                                                return Container(
                                                  height: _getCardHeight(w, h) * 0.65,
                                                  color: Colors.grey[200],
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        Colors.blue[700]!,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Positioned(
                                              top: _getResponsiveHeight(h, 0.01),  // 1% of screen height
                                              right: _getResponsiveWidth(w, 0.02), // 2% of screen width
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: _getResponsiveWidth(w, 0.025), // 2.5% of screen width
                                                  vertical: _getResponsiveHeight(h, 0.008),   // 0.8% of screen height
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(_getResponsiveWidth(w, 0.04)), // 4% of screen width
                                                ),
                                                child: Text(
                                                  'RS ${product['price']}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: _getResponsiveFontSize(w, 12),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(_getResponsiveWidth(w, 0.03)), // 3% of screen width
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product['name'],
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: _getResponsiveFontSize(w, 14),
                                                      color: Colors.black87,
                                                      height: 1.2,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  // SizedBox(height: _getResponsiveHeight(h, 0.005)), // 0.5% of screen height
                                                  // Text(
                                                  //   product['category'] ?? 'Engine',
                                                  //   style: TextStyle(
                                                  //     color: Colors.grey[600],
                                                  //     fontSize: _getResponsiveFontSize(w, 12),
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: filteredProducts.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}