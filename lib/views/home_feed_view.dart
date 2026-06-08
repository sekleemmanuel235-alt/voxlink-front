import 'package:flutter/material.dart';
import '../widgets/translation_mode_picker.dart';
import '../widgets/voxlink_badge.dart';

class HomeFeedView extends StatefulWidget {
  const HomeFeedView({super.key});
  @override
  State<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends State<HomeFeedView> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  // Per-video translation mode stored by index
  final Map<int, TranslationMode> _modes = {};

  TranslationMode _modeFor(int i) => _modes[i] ?? TranslationMode.subtitles;

  // Feed items — in production loaded from /api/v3/feed
  final List<Map<String, dynamic>> _feed = [
    {
      'bg': 0xFF1A1A2E, 'accent': 0xFFFF6B00,
      'author': '@voxlink_official', 'authorLang': 'FR',
      'caption': 'VoxLink traduit ta voix en temps réel. Parle à n\'importe qui, dans n\'importe quelle langue. 🌍',
      'originalCaption': 'VoxLink translates your voice in real-time. Talk to anyone, in any language. 🌍',
      'tag': 'VoxLink AI', 'likes': '12.4K', 'comments': '843',
      'isOriginalLang': 'EN',
    },
    {
      'bg': 0xFF0D1B2A, 'accent': 0xFF3797EF,
      'author': '@hannalindqvist', 'authorLang': 'SV',
      'caption': 'Ingen språkbarriär kan stoppa kärlek. ❤️ — Aucune barrière linguistique n\'arrête l\'amour.',
      'originalCaption': 'Ingen språkbarriär kan stoppa kärlek. ❤️',
      'tag': 'NOUVEAU', 'likes': '8.1K', 'comments': '302',
      'isOriginalLang': 'SV',
    },
    {
      'bg': 0xFF1B0032, 'accent': 0xFF8B3DFF,
      'author': '@tokyo_beats', 'authorLang': 'JA',
      'caption': '言葉を超えて、心がつながる。 — Au-delà des mots, les cœurs se connectent.',
      'originalCaption': '言葉を超えて、心がつながる。',
      'tag': 'TENDANCE', 'likes': '31.2K', 'comments': '1.2K',
      'isOriginalLang': 'JA',
    },
    {
      'bg': 0xFF0A2E0A, 'accent': 0xFF4CAF50,
      'author': '@paulo_br', 'authorLang': 'PT',
      'caption': 'O mundo fica menor quando você fala a língua de todos. 🌎 — Le monde rétrécit quand tu parles la langue de tous.',
      'originalCaption': 'O mundo fica menor quando você fala a língua de todos. 🌎',
      'tag': 'VIRAL', 'likes': '44.7K', 'comments': '2.1K',
      'isOriginalLang': 'PT',
    },
    {
      'bg': 0xFF2E1A00, 'accent': 0xFFFFC107,
      'author': '@series_original', 'authorLang': 'EN',
      'caption': '"The beginning of the end is always the hardest part." — Opening série — Désactivez la traduction pour la VO.',
      'originalCaption': '"The beginning of the end is always the hardest part."',
      'tag': 'SÉRIE VO', 'likes': '5.3K', 'comments': '217',
      'isOriginalLang': 'EN',
      'preferVO': true,  // hint to default to VO for this type of content
    },
  ];

  @override
  void initState() {
    super.initState();
    // For content tagged as VO (series openings etc.), default to VO mode
    for (int i = 0; i < _feed.length; i++) {
      if (_feed[i]['preferVO'] == true) {
        _modes[i] = TranslationMode.off;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PageView.builder(
        controller: _pageCtrl,
        scrollDirection: Axis.vertical,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemCount: _feed.length,
        itemBuilder: (ctx, i) => _buildCard(_feed[i], i),
      ),
      // Progress dots
      Positioned(
        right: 10, top: 0, bottom: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_feed.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 4, height: i == _currentPage ? 22 : 6,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: i == _currentPage ? const Color(0xFFFF6B00) : Colors.white38,
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ),
    ]);
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    final mode = _modeFor(index);
    final showOriginal = mode == TranslationMode.off;
    final showSubtitles = mode == TranslationMode.subtitles;
    final caption = showOriginal ? item['originalCaption'] : item['caption'];

    return Container(
      decoration: BoxDecoration(color: Color(item['bg'])),
      child: Stack(children: [
        // Decorative background
        Positioned(top: -80, right: -80, child: Container(
          width: 220, height: 220,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Color(item['accent']).withOpacity(0.12)),
        )),
        Positioned(bottom: -60, left: -60, child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Color(item['accent']).withOpacity(0.08)),
        )),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 56, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Color(item['accent']), borderRadius: BorderRadius.circular(6)),
                  child: Text(item['tag'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 10),
                // Author
                Row(children: [
                  CircleAvatar(radius: 14, backgroundColor: Color(item['accent']).withOpacity(0.3),
                    child: Text(item['authorLang'], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 8),
                  Text(item['author'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                // Caption (translated or original depending on mode)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    caption,
                    key: ValueKey('$index-$mode'),
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                  ),
                ),
                // Subtitle indicator
                if (showSubtitles && item['isOriginalLang'] != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.subtitles, color: Color(0xFFFF6B00), size: 12),
                    const SizedBox(width: 4),
                    Text('Traduit depuis ${item['isOriginalLang']}', style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 10)),
                  ]),
                ],
                if (mode == TranslationMode.audioTranslated) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.graphic_eq, color: Colors.greenAccent, size: 12),
                    const SizedBox(width: 4),
                    const Text('Audio traduit par VoxLink AI', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                  ]),
                ],
              ],
            ),
          ),
        ),

        // ── Translation mode picker (top center) ────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0, right: 60,
          child: Center(
            child: TranslationModePicker(
              current: mode,
              onChanged: (m) => setState(() => _modes[index] = m),
            ),
          ),
        ),

        // Right action buttons
        Positioned(
          right: 10, bottom: 110,
          child: Column(children: [
            _actionBtn(Icons.favorite_border, item['likes']),
            const SizedBox(height: 18),
            _actionBtn(Icons.comment_outlined, item['comments']),
            const SizedBox(height: 18),
            _actionBtn(Icons.share_outlined, ''),
            const SizedBox(height: 18),
            SeksonBadge(active: mode != TranslationMode.off, onTap: () {
              setState(() => _modes[index] = mode == TranslationMode.off ? TranslationMode.subtitles : TranslationMode.off);
            }),
          ]),
        ),

        // Bottom gradient + music bar
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            height: 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87]),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Icon(Icons.music_note, color: Colors.white60, size: 13),
                const SizedBox(width: 6),
                Text(item['author'], style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(width: 4),
                Text('· ${item['isOriginalLang']} Original', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white, size: 26, shadows: const [Shadow(blurRadius: 8)]),
      if (label.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, shadows: [Shadow(blurRadius: 6)])),
      ],
    ],
  );
}
