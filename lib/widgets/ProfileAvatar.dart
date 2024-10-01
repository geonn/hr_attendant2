import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 50,
        backgroundImage: (imageUrl != null && imageUrl != "")
            ? NetworkImage(imageUrl!)
            : const AssetImage('assets/images/panda.png')
                as ImageProvider<Object>,
        child: Icon(Icons.edit, color: Theme.of(context).primaryColor),
      ),
    );
  }
}
