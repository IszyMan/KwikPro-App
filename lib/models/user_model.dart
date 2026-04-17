class UserModel {
  final String uid;
  final String phone;
  final String role; // user or technician
  final String? profilePic;
  final String? currentAddress;
  final double? lat;
  final double? lng;

  UserModel({
    required this.uid,
    required this.phone,
    required this.role,
    this.profilePic,
    this.currentAddress,
    this.lat,
    this.lng,
  });

  // Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'role': role,
      'profilePic': profilePic ?? '',
      'currentAddress': currentAddress,
      'lat': lat,
      'lng': lng,
    };
  }

  // From Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      profilePic: map['profilePic'],
      currentAddress: map['currentAddress'],
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }
}