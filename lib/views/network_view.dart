import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/user_avatar.dart';

class NetworkView extends StatefulWidget {
  final String myUserId;
  const NetworkView({super.key, required this.myUserId});
  @override
  State<NetworkView> createState() => _NetworkViewState();
}

class _NetworkViewState extends State<NetworkView> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _contacts = [];
  List<dynamic> _searchResults = [];
  bool _loadingContacts = true;
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  String? _addError;
  String? _addSuccess;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loadingContacts = true);
    try {
      final c = await ApiService.getContacts();
      if (mounted) setState(() { _contacts = c; _loadingContacts = false; });
    } catch (_) { if (mounted) setState(() => _loadingContacts = false); }
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) { setState(() => _searchResults = []); return; }
    setState(() => _searching = true);
    try {
      final r = await ApiService.searchUsers(q.trim());
      if (mounted) setState(() { _searchResults = r; _searching = false; });
    } catch (_) { if (mounted) setState(() => _searching = false); }
  }

  Future<void> _addContact(String username) async {
    setState(() { _addError = null; _addSuccess = null; });
    try {
      final res = await ApiService.addContact(username, nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim());
      if (res['status'] == 'added') {
        setState(() => _addSuccess = 'Contact ajouté !');
        _loadContacts();
      } else {
        setState(() => _addError = res['detail'] ?? 'Erreur.');
      }
    } catch (e) { setState(() => _addError = 'Erreur réseau.'); }
  }

  Future<void> _removeContact(String contactId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le contact'),
        content: Text('Retirer $name de vos contacts ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.removeContact(contactId);
      _loadContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Réseau', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.person_add_outlined, color: Color(0xFFFF6B00)), onPressed: _showAddDialog),
        ]),
      ),
      TabBar(
        controller: _tabs,
        labelColor: const Color(0xFFFF6B00),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFFFF6B00),
        tabs: [Tab(text: 'Contacts (${_contacts.length})'), const Tab(text: 'Rechercher')],
      ),
      Expanded(
        child: TabBarView(controller: _tabs, children: [
          _buildContactsList(),
          _buildSearchTab(),
        ]),
      ),
    ]);
  }

  Widget _buildContactsList() {
    if (_loadingContacts) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
    if (_contacts.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
      const SizedBox(height: 12),
      const Text('Aucun contact', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ElevatedButton(
        onPressed: _showAddDialog,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white),
        child: const Text('Ajouter un contact'),
      ),
    ]));
    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (ctx, i) {
          final c = _contacts[i];
          final name = (c['fullname']?.toString().isNotEmpty == true) ? c['fullname'] : '@${c['username'] ?? '?'}';
          final initials = name.replaceAll('@','').length >= 2 ? name.replaceAll('@','').substring(0, 2).toUpperCase() : '??';
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Stack(children: [
              UserAvatar(initials: initials, radius: 22, isOnline: c['is_online'] == true, isPremium: c['is_premium'] == true),
            ]),
            title: Row(children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (c['is_verified'] == true) ...[const SizedBox(width: 4), const Icon(Icons.verified, size: 14, color: Color(0xFF3797EF))],
              if (c['is_premium'] == true) ...[const SizedBox(width: 4), const Icon(Icons.star, size: 12, color: Color(0xFFFF6B00))],
            ]),
            subtitle: Text('🌍 ${(c['system_lang'] ?? '?').toUpperCase()}  ${c['nickname'] != null ? "· ${c['nickname']}" : ""}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            trailing: IconButton(icon: const Icon(Icons.more_vert, size: 18), onPressed: () => _showContactOptions(c)),
          );
        },
      ),
    );
  }

  Widget _buildSearchTab() => Column(children: [
    Padding(
      padding: const EdgeInsets.all(14),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
          hintText: 'Rechercher par nom ou @utilisateur...',
          hintStyle: const TextStyle(fontSize: 13),
          suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B00)))) : null,
        ),
      ),
    ),
    Expanded(
      child: _searchResults.isEmpty
          ? Center(child: Text(_searchCtrl.text.length < 2 ? 'Tapez au moins 2 caractères.' : 'Aucun résultat.', style: const TextStyle(color: Colors.grey, fontSize: 13)))
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (ctx, i) {
                final u = _searchResults[i];
                final name = (u['fullname']?.toString().isNotEmpty == true) ? u['fullname'] : '@${u['username'] ?? '?'}';
                final initials = name.replaceAll('@','').length >= 2 ? name.replaceAll('@','').substring(0,2).toUpperCase() : '??';
                return ListTile(
                  leading: UserAvatar(initials: initials, radius: 20),
                  title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('@${u['username'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: ElevatedButton(
                    onPressed: () => _addContact(u['username']),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), minimumSize: Size.zero),
                    child: const Text('Ajouter', style: TextStyle(fontSize: 12)),
                  ),
                );
              },
            ),
    ),
  ]);

  void _showAddDialog() {
    _nicknameCtrl.clear(); _addError = null; _addSuccess = null;
    final usernameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Ajouter un contact", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: usernameCtrl, decoration: const InputDecoration(hintText: "@nom_utilisateur", prefixIcon: Icon(Icons.person_outline, size: 18))),
          const SizedBox(height: 12),
          TextField(controller: _nicknameCtrl, decoration: const InputDecoration(hintText: "Surnom (optionnel)", prefixIcon: Icon(Icons.tag, size: 18))),
          if (_addError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_addError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          if (_addSuccess != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_addSuccess!, style: const TextStyle(color: Colors.green, fontSize: 12))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              await _addContact(usernameCtrl.text.trim());
              setS(() {});
              if (_addSuccess != null) Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      )),
    );
  }

  void _showContactOptions(Map<String, dynamic> contact) {
    final name = contact['fullname']?.isNotEmpty == true ? contact['fullname'] : '@${contact['username']}';
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.person_outline), title: Text(name), subtitle: const Text('Voir le profil')),
      const Divider(height: 1),
      ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          onTap: () { Navigator.pop(context); _removeContact(contact['contact_id'], name); }),
    ])));
  }

  @override
  void dispose() { _tabs.dispose(); _searchCtrl.dispose(); _nicknameCtrl.dispose(); super.dispose(); }
}
