class UserModel {
  final String uid;
  final String phone;
  final String role; // user or technician

  UserModel({
    required this.uid,
    required this.phone,
    required this.role,
  });

  // Convert to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'role': role,
    };
  }

  // From Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
    );
  }
}