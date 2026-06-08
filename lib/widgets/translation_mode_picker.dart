import 'package:flutter/material.dart';

enum TranslationMode { off, subtitles, audioTranslated }

class TranslationModePicker extends StatelessWidget {
  final TranslationMode current;
  final ValueChanged<TranslationMode> onChanged;

  const TranslationModePicker({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip('VO', TranslationMode.off, Icons.music_note),
          _chip('Sous-titres', TranslationMode.subtitles, Icons.subtitles),
          _chip('Audio', TranslationMode.audioTranslated, Icons.translate),
        ],
      ),
    );
  }

  Widget _chip(String label, TranslationMode mode, IconData icon) {
    final isSelected = current == mode;
    return GestureDetector(
      onTap: () => onChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: Colors.white),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
