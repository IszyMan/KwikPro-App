import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String userId;
  final String technicianId;
  final String requestId;
  final String review;

  final double rating;
  final double priceRating;
  final double serviceRating;

  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.technicianId,
    required this.requestId,
    required this.review,
    required this.rating,
    required this.priceRating,
    required this.serviceRating,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "technicianId": technicianId,
      "requestId": requestId,
      "review": review,
      "rating": rating,
      "priceRating": priceRating,
      "serviceRating": serviceRating,
      "createdAt": createdAt,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      technicianId: map['technicianId'] ?? '',
      requestId: map['requestId'] ?? '',
      review: map['review'] ?? '',
      rating: (map['rating'] as num).toDouble(),
      priceRating: (map['priceRating'] as num).toDouble(),
      serviceRating: (map['serviceRating'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}