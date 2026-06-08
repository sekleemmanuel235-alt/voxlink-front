import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final bool isOnline;
  final bool isPremium;
  final Color? color;

  const UserAvatar({
    super.key,
    required this.initials,
    this.radius = 22,
    this.isOnline = false,
    this.isPremium = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: color ?? Colors.indigo.withOpacity(0.75),
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.55,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: radius * 0.45,
              height: radius * 0.45,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        if (isPremium)
          Positioned(
            right: 0, top: 0,
            child: Container(
              width: radius * 0.45,
              height: radius * 0.45,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B00),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star, size: radius * 0.3, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
