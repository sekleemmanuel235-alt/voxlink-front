import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import 'call_screen.dart';

class ChatView extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback? onMessagesRead;
  const ChatView({super.key, required this.profile, this.onMessagesRead});
  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _openContactId;
  Map<String, dynamic>? _openContact;
  List<dynamic> _messages = [];
  bool _loadingMessages = false;
  bool _isTranslationActive = true;
  bool _contactIsTyping = false;
  final _msgCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _registerWsHandlers();
  }

  void _registerWsHandlers() {
    WebSocketService.instance.on('new_message', _onNewMessage);
    WebSocketService.instance.on('typing_start', _onTypingStart);
    WebSocketService.instance.on('typing_stop', _onTypingStop);
  }

  void _onNewMessage(Map<String, dynamic> data) {
    final convId = data['conversation_id'];
    final msg = data['message'] as Map<String, dynamic>?;
    if (msg == null) return;
    if (_openContactId != null) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
    }
    _loadConversations();
  }

  void _onTypingStart(Map<String, dynamic> data) {
    if (data['from'] == _openContactId) setState(() => _contactIsTyping = true);
  }
  void _onTypingStop(Map<String, dynamic> data) {
    if (data['from'] == _openContactId) setState(() => _contactIsTyping = false);
  }

  Future<void> _loadConversations() async {
    try {
      final c = await ApiService.getConversations();
      if (mounted) setState(() { _conversations = c; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _openConversation(Map<String, dynamic> contact) async {
    setState(() {
      _openContactId = contact['id'];
      _openContact = contact;
      _loadingMessages = true;
      _messages = [];
    });
    widget.onMessagesRead?.call();
    try {
      final msgs = await ApiService.getMessages(contact['id']);
      if (mounted) setState(() { _messages = msgs; _loadingMessages = false; });
      _scrollToBottom();
    } catch (_) { if (mounted) setState(() => _loadingMessages = false); }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _openContactId == null) return;
    _msgCtrl.clear();
    WebSocketService.instance.sendTypingStop(_openContactId!);

    setState(() => _messages.add({
      'sender_id': ApiService.userId, 'original_text': text,
      'translated_text': null, 'is_translated': false,
      'created_at': DateTime.now().toIso8601String(),
    }));
    _scrollToBottom();

    try {
      await ApiService.sendMessage(toUserId: _openContactId!, text: text, translationActive: _isTranslationActive);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
    });
  }

  void _onSearchChanged(String query) async {
    if (query.trim().length < 2) { _loadConversations(); return; }
    try {
      final results = await ApiService.searchUsers(query.trim());
      // Show search results as potential conversations
      if (mounted) setState(() {
        _conversations = results.map((u) => {
          'contact': u, 'last_message': null, 'unread_count': 0,
          'conversation_id': u['id'],
        }).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_openContactId != null && _openContact != null) return _buildChat();
    return _buildList();
  }

  Widget _buildList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
            hintText: 'Rechercher des contacts...',
            hintStyle: const TextStyle(fontSize: 13),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _searchCtrl.clear(); _loadConversations(); })
                : null,
          ),
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
            : _conversations.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadConversations,
                    child: ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (ctx, i) {
                        final conv = _conversations[i];
                        final contact = conv['contact'] as Map<String, dynamic>? ?? {};
                        final lm = conv['last_message'] as Map<String, dynamic>?;
                        final unread = (conv['unread_count'] ?? 0) as int;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: _avatar(contact),
                          title: Row(children: [
                            Expanded(child: Text(
                              contact['fullname']?.isNotEmpty == true ? contact['fullname'] : '@${contact['username'] ?? ''}',
                              style: TextStyle(fontSize: 14, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600),
                            )),
                            if (lm != null) Text(_formatTime(lm['created_at']), style: TextStyle(fontSize: 10, color: unread > 0 ? const Color(0xFFFF6B00) : Colors.grey)),
                          ]),
                          subtitle: Row(children: [
                            Expanded(child: Text(
                              lm != null ? '${lm['is_mine'] == true ? "Vous: " : ""}${lm['text'] ?? ''}' : '🌍 Langues : ${(contact['system_lang'] ?? '?').toUpperCase()}',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            )),
                            if (unread > 0) Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFF6B00), borderRadius: BorderRadius.circular(10)),
                              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                          onTap: () => _openConversation(contact),
                        );
                      },
                    ),
                  ),
      ),
    ]);
  }

  Widget _buildChat() {
    final contact = _openContact!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myId = ApiService.userId;
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111113) : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
        ),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { setState(() { _openContactId = null; _openContact = null; }); _loadConversations(); }),
          _avatar(contact, radius: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(contact['fullname']?.isNotEmpty == true ? contact['fullname'] : '@${contact['username'] ?? ''}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            _contactIsTyping
                ? const Text('est en train d\'écrire...', style: TextStyle(color: Colors.green, fontSize: 10))
                : Text(contact['is_online'] == true ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(fontSize: 10, color: contact['is_online'] == true ? Colors.green : Colors.grey)),
          ])),
          // Translation toggle
          GestureDetector(
            onTap: () => setState(() => _isTranslationActive = !_isTranslationActive),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isTranslationActive ? const Color(0xFFFF6B00) : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.translate, color: Colors.white, size: 10),
                const SizedBox(width: 3),
                Text(_isTranslationActive ? 'IA ON' : 'IA OFF',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          IconButton(icon: const Icon(Icons.phone, size: 20), onPressed: () => _initiateCall(false)),
          IconButton(icon: const Icon(Icons.videocam, size: 20), onPressed: () => _initiateCall(true)),
        ]),
      ),
      // Language hint
      Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: const Color(0xFFFF6B00).withOpacity(0.08),
        child: Center(child: Text(
          'Vous : ${widget.profile['system_lang']?.toUpperCase() ?? '?'} → Contact : ${(contact['system_lang'] ?? '?').toUpperCase()} • Traduction ${_isTranslationActive ? "active" : "désactivée"}',
          style: const TextStyle(fontSize: 10, color: Color(0xFFFF6B00), fontWeight: FontWeight.w600),
        )),
      ),
      // Messages
      Expanded(
        child: _loadingMessages
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
            : _messages.isEmpty
                ? const Center(child: Text('Envoyez votre premier message 👋', style: TextStyle(color: Colors.grey, fontSize: 13)))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i];
                      final isMe = m['sender_id'] == myId;
                      return _buildBubble(m, isMe);
                    },
                  ),
      ),
      // Input
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111113) : Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
        ),
        child: Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _msgCtrl,
                onChanged: (v) {
                  if (v.isNotEmpty) WebSocketService.instance.sendTypingStart(_openContactId!);
                  else WebSocketService.instance.sendTypingStop(_openContactId!);
                },
                decoration: const InputDecoration(hintText: 'Votre message...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 13), isDense: true),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              )),
              IconButton(icon: const Icon(Icons.send, color: Color(0xFFFF6B00), size: 18), onPressed: _sendMessage),
            ]),
          )),
        ]),
      ),
    ]);
  }

  Widget _buildBubble(Map<String, dynamic> m, bool isMe) {
    final hasTranslation = m['translated_text'] != null && m['translated_text'] != m['original_text'];
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF8B3DFF) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isMe ? (m['original_text'] ?? '') : (m['translated_text'] ?? m['original_text'] ?? ''),
              style: TextStyle(fontSize: 13, color: isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87))),
          if (!isMe && hasTranslation) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.translate, size: 9, color: Colors.grey),
              const SizedBox(width: 3),
              Expanded(child: Text(m['original_text'] ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic))),
            ]),
          ],
          const SizedBox(height: 2),
          Text(_formatTime(m['created_at']), style: TextStyle(fontSize: 8, color: isMe ? Colors.white60 : Colors.grey)),
        ]),
      ),
    );
  }

  void _initiateCall(bool isVideo) {
    if (_openContact == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(
      contact: _openContact!, myProfile: widget.profile, isVideoCall: isVideo,
    )));
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
    const SizedBox(height: 16),
    const Text('Aucune conversation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
    const SizedBox(height: 8),
    const Text('Ajoutez des contacts depuis l\'onglet Réseau.', style: TextStyle(fontSize: 13, color: Colors.grey)),
  ]));

  Widget _avatar(Map<String, dynamic> contact, {double radius = 22}) {
    final name = (contact['fullname']?.isNotEmpty == true ? contact['fullname'] : contact['username']) ?? '?';
    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.indigo.withOpacity(0.8),
      child: Text(initials, style: TextStyle(color: Colors.white, fontSize: radius * 0.6, fontWeight: FontWeight.bold)),
    );
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month) return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      return '${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }

  @override
  void dispose() {
    WebSocketService.instance.off('new_message', _onNewMessage);
    WebSocketService.instance.off('typing_start', _onTypingStart);
    WebSocketService.instance.off('typing_stop', _onTypingStop);
    _msgCtrl.dispose(); _searchCtrl.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }
}
