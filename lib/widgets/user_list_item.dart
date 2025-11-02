// lib/widgets/user_list_item.dart

import 'package:flutter/material.dart';

class UserListItem extends StatelessWidget {
  final String? imageUrl;
  final String userName;
  final String lastMessage;
  final VoidCallback onTap;

  const UserListItem({
    Key? key,
    required this.userName,
    required this.lastMessage,
    required this.onTap,
    this.imageUrl, // make imageUrl optional
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white12,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Handle cases where there is no image
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFD4AF37),
              backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                  ? NetworkImage(imageUrl!)
                  : null,
              child: imageUrl == null || imageUrl!.isEmpty
                  ? const Icon(Icons.person, color: Colors.black, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}