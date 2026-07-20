import 'package:flutter/material.dart';

class UserTechnicianAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;

  /// Shows the green online dot
  final bool isOnline;

  const UserTechnicianAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 28,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    final scale =
    (MediaQuery.of(context).size.height / 850).clamp(0.9, 1.0);

    final avatarRadius = radius * scale;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty
                ? Icon(
              Icons.person,
              size: avatarRadius,
              color: Colors.grey.shade600,
            )
                : null,
          ),
        ),

        if (isOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: avatarRadius * 0.42,
              height: avatarRadius * 0.42,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}