import 'package:flutter/material.dart';
import '../models/languages.dart';

/// Sélecteur de langue avec recherche intégrée.
/// Supporte les 100+ langues ISO 639-1 supportées par le moteur VoxLink AI/OpenRouter.
/// Aucune restriction de langue — passe n'importe quel code ISO valide.
class LanguagePicker extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<String> onSelected;
  final String? label;

  const LanguagePicker({
    super.key,
    required this.selectedCode,
    required this.onSelected,
    this.label,
  });

  @override
  State<LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  void _open() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LanguageSearchSheet(
        currentCode: widget.selectedCode,
        onSelected: (code) { Navigator.pop(context); widget.onSelected(code); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguages.findByCode(widget.selectedCode);
    final flag = lang?['flag'] ?? '🌍';
    final label = lang?['label'] ?? widget.selectedCode.toUpperCase();
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1C1C1E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          if (widget.label != null) ...[
            Icon(Icons.language, color: Colors.grey, size: 18),
            const SizedBox(width: 10),
            Text(widget.label!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const Spacer(),
          ],
          Text('$flag $label', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
        ]),
      ),
    );
  }
}

class _LanguageSearchSheet extends StatefulWidget {
  final String currentCode;
  final ValueChanged<String> onSelected;
  const _LanguageSearchSheet({required this.currentCode, required this.onSelected});
  @override
  State<_LanguageSearchSheet> createState() => _LanguageSearchSheetState();
}

class _LanguageSearchSheetState extends State<_LanguageSearchSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, String>> _filtered = AppLanguages.all;

  void _filter(String q) {
    final query = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? AppLanguages.all
          : AppLanguages.all.where((l) =>
              l['label']!.toLowerCase().contains(query) ||
              l['code']!.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _ctrl,
            onChanged: _filter,
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
              hintText: 'Rechercher une langue... (${kSupportedLanguages.length} disponibles)',
              hintStyle: const TextStyle(fontSize: 13),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 16),
                      onPressed: () { _ctrl.clear(); _filter(''); })
                  : null,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollCtrl,
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final l = _filtered[i];
              final isSelected = l['code'] == widget.currentCode;
              return ListTile(
                dense: true,
                leading: Text(l['flag']!, style: const TextStyle(fontSize: 20)),
                title: Text(l['label']!, style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(l['code']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFFF6B00), size: 18) : null,
                onTap: () => widget.onSelected(l['code']!),
              );
            },
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
