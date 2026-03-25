class TechnicianModel {
  final String uid;
  final String name;
  final String service;
  final String address;

  final double? lat;
  final double? long;

  final String? profilePic;
  final String? workCertificate;
  final String? ninImage;
  final bool isOnline;

  TechnicianModel({
    required this.uid,
    required this.name,
    required this.service,
    required this.address,
    this.lat,
    this.long,
    this.profilePic,
    this.workCertificate,
    this.ninImage,
    this.isOnline = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'service': service,
      'location': address, // keep this consistent
      'lat': lat,
      'long': long,
      'profilePic': profilePic ?? '',
      'workCertificate': workCertificate ?? '',
      'ninImage': ninImage ?? '',
      'isOnline': isOnline,
    };
  }

  factory TechnicianModel.fromMap(Map<String, dynamic> map) {
    return TechnicianModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      service: map['service'] ?? '',


      address: map['location'] ?? '',

      //  SAFE double parsing
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      long: map['long'] != null ? (map['long'] as num).toDouble() : null,

      // SAFE nullable strings
      profilePic: map['profilePic'] ?? '',
      workCertificate: map['workCertificate'] ?? '',
      ninImage: map['ninImage'] ?? '',

      // SAFE boolean
      isOnline: map['isOnline'] ?? false,
    );
  }
}