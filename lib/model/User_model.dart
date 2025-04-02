class AppUser {
  String name;
  String id;
  String email;
  String password;
  String address;

  String phoneNumber;


  AppUser({
    required this.name,
    required this.id,
    required this.email,
    required this.password,
    required this.address,
    required this.phoneNumber,

  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
      'email': email,
      'password': password,
      'address': address,
      'phoneNumber': phoneNumber,

    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      name: map['name'],
      id: map['id'],
      email: map['email'],
      password: map['password'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],

    );
  }
}
