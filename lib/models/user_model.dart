class UserModel {
  final String uid;
  final String phone;
  final String role; // user or technician
  final String? profilePic;

  UserModel({
    required this.uid,
    required this.phone,
    required this.role,
    this.profilePic,
  });

  // Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'role': role,
      'profilePic': profilePic ?? '',
    };
  }

  // From Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      profilePic: map['profilePic'],
    );
  }
}