import 'package:flutter/material.dart';

class TActionAppbarIcon extends StatelessWidget {
  const TActionAppbarIcon({
    super.key,
    required this.onPressed,
    this.iconColor,
    required this.icon,
  });

  final VoidCallback onPressed;
  final Color? iconColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 26,
        color: iconColor,
      ),
    );
  }
}
