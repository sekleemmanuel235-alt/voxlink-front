import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});
  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _myGroups = [];
  List<Map<String, dynamic>> _discover = [];
  bool _loading = false;
  final _searchCtrl = TextEditingController();

  // Local group data — backend groups API to be added server-side
  // These are stored and managed locally per-user for now
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    // Simulated local groups — replace with real API call when groups endpoint added
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {
      _myGroups = [];
      _discover = [
        {'id':'disc1','name':'🌍 Expats Français','lang':'fr','members':1240,'description':'Communauté des francophones à l\'étranger.'},
        {'id':'disc2','name':'🇧🇷 Brasil & France','lang':'pt','members':853,'description':'Francophones et brésiliens — échanges culturels.'},
        {'id':'disc3','name':'🇯🇵 Japan Talk','lang':'ja','members':2100,'description':'Japonais et francophones — langue, culture, anime.'},
        {'id':'disc4','name':'🌐 Polyglots Hub','lang':'en','members':5420,'description':'Pour ceux qui parlent plusieurs langues.'},
        {'id':'disc5','name':'🇩🇪 Deutsch-Français','lang':'de','members':644,'description':'Échanges franco-allemands.'},
      ];
      _loading = false;
    });
  }

  void _createGroup() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String lang = ApiService.userId != null ? 'fr' : 'fr';
    final langs = [
      {'code':'fr','flag':'🇫🇷'},{'code':'en','flag':'🇬🇧'},{'code':'es','flag':'🇪🇸'},
      {'code':'pt','flag':'🇧🇷'},{'code':'de','flag':'🇩🇪'},{'code':'ja','flag':'🇯🇵'},
    ];
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Créer un groupe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom du groupe', prefixIcon: Icon(Icons.group_outlined, size: 18))),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.info_outline, size: 18))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: lang,
            decoration: const InputDecoration(labelText: 'Langue principale', prefixIcon: Icon(Icons.language, size: 18)),
            items: langs.map((l) => DropdownMenuItem(value: l['code']!, child: Text('${l['flag']} ${l['code']!.toUpperCase()}'))).toList(),
            onChanged: (v) { if (v != null) setS(() => lang = v); },
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() => _myGroups.insert(0, {
                'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
                'name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'lang': lang, 'members': 1, 'isAdmin': true,
              }));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Créer', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      )),
    );
  }

  void _openGroup(Map<String, dynamic> group) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _GroupChatPage(group: group)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
        child: Row(children: [
          const Text('Groupes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF6B00)), onPressed: _createGroup),
        ]),
      ),
      TabBar(
        controller: _tabs,
        labelColor: const Color(0xFFFF6B00),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFFFF6B00),
        tabs: [Tab(text: 'Mes groupes (${_myGroups.length})'), const Tab(text: 'Découvrir')],
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _buildMyGroups(),
        _buildDiscover(),
      ])),
    ]);
  }

  Widget _buildMyGroups() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
    if (_myGroups.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
      const SizedBox(height: 16),
      const Text('Aucun groupe', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Créez ou rejoignez un groupe\npour parler à plusieurs dans votre langue.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _createGroup,
        icon: const Icon(Icons.add), label: const Text('Créer un groupe'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white),
      ),
    ]));
    return ListView.builder(
      itemCount: _myGroups.length,
      itemBuilder: (ctx, i) => _groupTile(_myGroups[i], mine: true),
    );
  }

  Widget _buildDiscover() => ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: _discover.length,
    itemBuilder: (ctx, i) => _groupTile(_discover[i], mine: false),
  );

  Widget _groupTile(Map<String, dynamic> g, {required bool mine}) {
    final name = g['name'] as String;
    final members = g['members'] as int;
    final desc = g['description'] as String? ?? '';
    final initials = name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final firstLetters = initials.split(' ').take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF6B00).withOpacity(0.15),
          child: Text(firstLetters.isEmpty ? '?' : firstLetters,
              style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 13))),
        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (desc.isNotEmpty) Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.people, size: 12, color: Colors.grey),
            const SizedBox(width: 3),
            Text('$members membres', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 8),
            const Icon(Icons.translate, size: 12, color: Color(0xFFFF6B00)),
            const SizedBox(width: 3),
            Text('VoxLink AI', style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B00), fontWeight: FontWeight.w600)),
          ]),
        ]),
        trailing: mine
            ? IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF6B00)), onPressed: () => _openGroup(g))
            : ElevatedButton(
                onPressed: () {
                  setState(() {
                    _discover.removeWhere((d) => d['id'] == g['id']);
                    _myGroups.add({...g, 'members': (g['members'] as int) + 1});
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('Rejoindre', style: TextStyle(fontSize: 12)),
              ),
      ),
    );
  }

  @override
  void dispose() { _tabs.dispose(); _searchCtrl.dispose(); super.dispose(); }
}

/// Écran de chat de groupe avec traduction automatique par membre
class _GroupChatPage extends StatefulWidget {
  final Map<String, dynamic> group;
  const _GroupChatPage({required this.group});
  @override
  State<_GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<_GroupChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _translationActive = true;

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() => _messages.add({
      'sender': ApiService.userId ?? 'Moi',
      'text': text,
      'isMe': true,
      'time': DateTime.now().toIso8601String(),
    }));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.group['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text('${widget.group['members']} membres', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _translationActive = !_translationActive),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _translationActive ? const Color(0xFFFF6B00) : Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.translate, size: 10, color: Colors.white),
                const SizedBox(width: 3),
                Text(_translationActive ? 'IA ON' : 'IA OFF',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ),
      body: Column(children: [
        if (_translationActive)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFFFF6B00).withOpacity(0.08),
            child: const Center(child: Text('Messages traduits automatiquement dans votre langue',
                style: TextStyle(fontSize: 10, color: Color(0xFFFF6B00), fontWeight: FontWeight.w600))),
          ),
        Expanded(child: _messages.isEmpty
            ? const Center(child: Text('Soyez le premier à écrire 👋', style: TextStyle(color: Colors.grey, fontSize: 13)))
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(14),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final m = _messages[i];
                  final isMe = m['isMe'] == true;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF8B3DFF) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey[200]),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(16)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (!isMe) Text(m['sender'], style: const TextStyle(fontSize: 10, color: Color(0xFFFF6B00), fontWeight: FontWeight.bold)),
                        Text(m['text'], style: TextStyle(fontSize: 13, color: isMe ? Colors.white : null)),
                      ]),
                    ),
                  );
                },
              )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111113) : Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15)))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(hintText: 'Message...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 13), isDense: true),
              onSubmitted: (_) => _send(),
            )),
            IconButton(icon: const Icon(Icons.send, color: Color(0xFFFF6B00), size: 20), onPressed: _send),
          ]),
        ),
      ]),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }
}
