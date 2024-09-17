class Vendor {
  String id;
  String email;
  String password;
  String address;
  String phoneNumber;
  String? storeImage;
  String shopName;
  String vendorName;

  Vendor({
    required this.id,
    required this.email,
    required this.password,
    required this.address,
    required this.phoneNumber,
    this.storeImage,
    required this.shopName,
    required this.vendorName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'address': address,
      'phoneNumber': phoneNumber,
      'storeImage': storeImage,
      'shopName': shopName,
      'vendorName': vendorName,
    };
  }

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      storeImage: map['storeImage'],
      shopName: map['shopName'],
      vendorName: map['vendorName'],
    );
  }
}
