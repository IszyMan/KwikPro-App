import 'package:flutter/material.dart';

import 'user_technician_avatar.dart';
import 'user_technician_rating.dart';

class UserTechnicianHorizontalCard extends StatelessWidget {
  final String name;
  final String profession;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String? location;
  final String? distance;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isVerified;

  const UserTechnicianHorizontalCard({
    super.key,
    required this.name,
    required this.profession,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    this.location,
    this.distance,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scale =
    (MediaQuery.of(context).size.height / 850).clamp(0.90, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 270 * scale,
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Row(
              children: [
                UserTechnicianAvatar(
                  imageUrl: imageUrl,
                  radius: 30,
                  isOnline: true,
                ),

                SizedBox(width: 12 * scale),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          if (isVerified) ...[
                            SizedBox(width: 4 * scale),
                            Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 18 * scale,
                            ),
                          ],
                        ],
                      ),

                      SizedBox(height: 3 * scale),

                      Text(
                        profession,
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),





            UserTechnicianRating(
              rating: rating,
              reviewCount: reviewCount,
            ),

            SizedBox(height: 12 * scale),



            if (distance != null)
              Row(
                children: [

                  Icon(
                    Icons.access_time_rounded,
                    size: 16 * scale,
                    color: Colors.blue,
                  ),

                  SizedBox(width: 5 * scale),

                  Text(
                    distance!,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13 * scale,
                    ),
                  ),
                ],
              ),

            if (trailing != null) ...[
              SizedBox(height: 10 * scale),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}