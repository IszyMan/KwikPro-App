import 'package:flutter/material.dart';

import 'unread_badge.dart';

class ChatTile extends StatelessWidget {

  final String name;

  final String? image;

  final String lastMessage;

  final String time;

  final int unread;

  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.name,
    this.image,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return ListTile(

      onTap: onTap,

      leading: CircleAvatar(
        radius: 26,
        backgroundImage:
        image != null
            ? NetworkImage(image!)
            : null,
        child: image == null
            ? const Icon(Icons.person)
            : null,
      ),

      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 6),

          UnreadBadge(
            count: unread,
          ),
        ],
      ),
    );
  }
}