class TechnicianModel {
  final String uid;
  final String name;
  final String service;
  final List<String>? skills;
  final int yearsOfExperience;
  final String address;

  final double? lat;
  final double? lng;

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
  final double? distanceKm;
  final double recommendationScore;

  TechnicianModel({
    required this.uid,
    required this.name,
    required this.service,
    this.skills,
    required this.yearsOfExperience,
    required this.address,
    this.lat,
    this.lng,
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
    this.distanceKm,
    this.recommendationScore = 0,
  });

  TechnicianModel copyWith({
    String? uid,
    String? name,
    String? service,
    List<String>? skills,
    int? yearsOfExperience,
    String? address,
    double? lat,
    double? lng,
    String? profilePic,
    List<String>? workToolsImages,
    List<String>? previousWorkImages,
    String? workCertificate,
    String? ninImage,
    bool? isOnline,
    bool? isVerified,
    bool? isSuspended,
    int? completedJobs,
    double? avgPriceRating,
    double? avgServiceRating,
    double? distanceKm,
    double? recommendationScore,
  }) {
    return TechnicianModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      service: service ?? this.service,
      skills: skills ?? this.skills,
      yearsOfExperience:
      yearsOfExperience ?? this.yearsOfExperience,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      profilePic: profilePic ?? this.profilePic,
      workToolsImages:
      workToolsImages ?? this.workToolsImages,
      previousWorkImages:
      previousWorkImages ?? this.previousWorkImages,
      workCertificate:
      workCertificate ?? this.workCertificate,
      ninImage: ninImage ?? this.ninImage,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isSuspended: isSuspended ?? this.isSuspended,
      completedJobs:
      completedJobs ?? this.completedJobs,
      avgPriceRating:
      avgPriceRating ?? this.avgPriceRating,
      avgServiceRating:
      avgServiceRating ?? this.avgServiceRating,
      distanceKm: distanceKm ?? this.distanceKm,
      recommendationScore:
      recommendationScore ?? this.recommendationScore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'service': service,
      'skills': skills ?? [],
      'yearsOfExperience': yearsOfExperience,
      'location': address,
      'lat': lat,
      'lng': lng,
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
      yearsOfExperience: (map['yearsOfExperience'] as num?)?.toInt() ?? 0,
      address: map['location'] ?? '',
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
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