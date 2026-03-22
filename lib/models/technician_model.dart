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


});

  Map<String, dynamic> toMap(){
    return{
      'uid': uid,
      'name': name,
      'service': service,
      'location': address,
      'lat': lat,
      'long': long,
      'profilePic': profilePic ?? '',
      'workCertificate': workCertificate ?? '',
      'ninImage': ninImage,

    };
  }

  factory TechnicianModel.fromMap(Map<String, dynamic> map){
    return TechnicianModel(
      uid: map['uid'],
      name: map['name'],
      service: map['service'],
      address: map['address'],
      lat: (map['lat'] ?? 0).toDouble(),
      long: (map['long'] ?? 0).toDouble(),
      profilePic: map['profilePic'],
      workCertificate: map['workCertificate'],
      ninImage: map['ninImage'],
    );
  }
}