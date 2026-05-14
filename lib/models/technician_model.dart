class TechnicianModel {
  final String uid;
  final String name;
  final String service;
  final List<String>? skills;
  final int yearsOfExperience;
  final String address;

  final double? lat;
  final double? long;

  final String? profilePic;
  final List<String>? workToolsImages;
  final List<String>? previousWorkImages;
  final String? workCertificate;
  final String? ninImage;
  final bool isOnline;
  final bool isVerified;
  final bool isSuspended;
  final int? completedJobs;
  final double? avgPriceRating;
  final double? avgServiceRating;

  TechnicianModel({
    required this.uid,
    required this.name,
    required this.service,
    this.skills,
    required this.yearsOfExperience,
    required this.address,
    this.lat,
    this.long,
    this.profilePic,
    this.workToolsImages,
    this.previousWorkImages,
    this.workCertificate,
    this.ninImage,
    this.isOnline = false,
    this.isVerified = false,
    this.isSuspended =false,
    this.completedJobs,
    this.avgPriceRating,
    this.avgServiceRating,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'service': service,
      'skills': skills ?? [],
      'yearsOfExperience': yearsOfExperience,
      'location': address,
      'lat': lat,
      'long': long,
      'profilePic': profilePic ?? '',
      'workToolsImages': workToolsImages ?? [],
      'previousWorkImages': previousWorkImages ?? [],
      'workCertificate': workCertificate ?? '',
      'ninImage': ninImage ?? '',
      'isOnline': isOnline,
      'isVerified': isVerified,
      'isSuspended': isSuspended,
      'completedJobs': completedJobs,
      'avgPriceRating': avgPriceRating,
      'avgServiceRating': avgServiceRating,
    };
  }

  factory TechnicianModel.fromMap(Map<String, dynamic> map) {
    return TechnicianModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      service: map['service'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      yearsOfExperience: (map['yearsOfExperience'] ?? 0) as int,
      address: map['location'] ?? '',
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      long: map['long'] != null ? (map['long'] as num).toDouble() : null,
      profilePic: map['profilePic'] ?? '',
      workToolsImages:
      List<String>.from(map['workToolsImages'] ?? []),

      previousWorkImages:
      List<String>.from(map['previousWorkImages'] ?? []),
      workCertificate: map['workCertificate'] ?? '',
      ninImage: map['ninImage'] ?? '',
      isOnline: map['isOnline'] ?? false,
      isVerified: map['isVerified'] ?? false,
      isSuspended: map['isSuspended'] ?? false,
      completedJobs: map['completedJobs'] ?? 0,
      avgPriceRating: (map['avgPriceRating'] ?? 0).toDouble(),
      avgServiceRating: (map['avgServiceRating'] ?? 0).toDouble(),
    );
  }
}