import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import 'call_screen.dart';
import '../widgets/user_avatar.dart';

class CallsView extends StatefulWidget {
  final Map<String, dynamic> profile;
  const CallsView({super.key, required this.profile});
  @override
  State<CallsView> createState() => _CallsViewState();
}

class _CallsViewState extends State<CallsView> {
  List<dynamic> _history = [];
  bool _loading = true;
  Map<String, dynamic>? _incomingCall;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WebSocketService.instance.on('call_request', _onIncomingCall);
  }

  void _onIncomingCall(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() => _incomingCall = data);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: IncomingCallOverlay(
          callerPayload: data,
          onAccept: () {
            Navigator.pop(context);
            WebSocketService.instance.sendCallAccepted(data['from']);
            final contact = {'id': data['from'], 'username': data['from'], 'fullname': data['payload']?['caller_name'] ?? '', 'system_lang': data['payload']?['my_lang'] ?? 'en'};
            Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(contact: contact, myProfile: widget.profile)));
            setState(() => _incomingCall = null);
          },
          onReject: () {
            Navigator.pop(context);
            WebSocketService.instance.sendCallRejected(data['from']);
            setState(() => _incomingCall = null);
          },
        ),
      ),
    );
  }

  Future<void> _loadHistory() async {
    try {
      final h = await ApiService.getCallHistory();
      if (mounted) setState(() { _history = h; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Appels', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
            : _history.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (ctx, i) => _buildCallTile(_history[i]),
                    ),
                  ),
      ),
    ]);
  }

  Widget _buildCallTile(Map<String, dynamic> log) {
    final contact = log['contact'] as Map<String, dynamic>?;
    final isOutgoing = log['direction'] == 'outgoing';
    final dur = log['duration_sec'] as int? ?? 0;
    final wasTranslated = log['was_translated'] == true;
    final name = (contact?['fullname']?.toString().isNotEmpty == true) ? contact!['fullname'] : '@${contact?['username'] ?? '?'}';
    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    final durStr = dur > 0 ? '${dur ~/ 60}m ${dur % 60}s' : 'Non répondu';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: UserAvatar(initials: initials, radius: 22),
      title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Row(children: [
        Icon(isOutgoing ? Icons.call_made : Icons.call_received,
            size: 12, color: isOutgoing ? const Color(0xFF3797EF) : Colors.green),
        const SizedBox(width: 4),
        Text(durStr, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        if (wasTranslated) ...[
          const SizedBox(width: 6),
          const Icon(Icons.translate, size: 10, color: Color(0xFFFF6B00)),
          const Text(' VoxLink AI', style: TextStyle(fontSize: 9, color: Color(0xFFFF6B00), fontWeight: FontWeight.bold)),
        ],
      ]),
      trailing: contact != null
          ? IconButton(
              icon: const Icon(Icons.call, color: Color(0xFFFF6B00), size: 20),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(contact: contact, myProfile: widget.profile))),
            )
          : null,
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.phone_missed, size: 64, color: Colors.grey),
    const SizedBox(height: 16),
    const Text('Aucun appel récent', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Vos appels apparaîtront ici.', style: TextStyle(fontSize: 13, color: Colors.grey)),
  ]));

  @override
  void dispose() { WebSocketService.instance.off('call_request', _onIncomingCall); super.dispose(); }
}
