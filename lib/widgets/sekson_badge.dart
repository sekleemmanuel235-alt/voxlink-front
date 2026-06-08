import 'package:flutter/material.dart';

class SeksonBadge extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  final String? label;

  const SeksonBadge({super.key, this.active = true, this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF6B00) : Colors.grey[700],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, color: Colors.white, size: 10),
            const SizedBox(width: 3),
            Text(
              label ?? (active ? 'IA ON' : 'IA OFF'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
