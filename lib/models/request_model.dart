class RequestModel {
  final String id;
  final String userId;
  final String technicianId;
  final String service;
  final String serviceLocationAddress;
  final String description;
  final String? imageUrl;
  final double userLat;
  final double userLng;
  final String status;
  final double? price;
  final Map<String, dynamic> timeline;

  RequestModel({
    required this.id,
    required this.userId,
    required this.technicianId,
    required this.service,
    required this.serviceLocationAddress,
    required this.description,
    this.imageUrl,
    required this.userLat,
    required this.userLng,
    required this.status,
    this.price,
    required this.timeline,
  });

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "technicianId": technicianId,
      "service": service,
      "serviceLocationAddress": serviceLocationAddress,
      "description": description,
      "imageUrl": imageUrl,
      "userLat": userLat,
      "userLng": userLng,
      "status": status,
      "price": price,
      "timeline": timeline,
    };
  }
}