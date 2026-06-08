import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../services/websocket_service.dart';

class CallScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  final Map<String, dynamic> myProfile;
  final bool isVideoCall;
  const CallScreen({super.key, required this.contact, required this.myProfile, this.isVideoCall = false});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  String _callStatus = 'Appel en cours...';
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isTranslationActive = true;
  bool _callAnswered = false;
  bool _callEnded = false;
  String? _callId;
  int _durationSeconds = 0;
  double _cloneRatio = 0.0;
  bool _wasTranslated = false;
  Timer? _timer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  String get _contactName =>
      (widget.contact['fullname']?.toString().isNotEmpty == true)
          ? widget.contact['fullname']
          : '@${widget.contact['username'] ?? '?'}';

  String get _contactInitials {
    final n = _contactName.replaceAll('@', '');
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n.toUpperCase();
  }

  bool get _langsDiffer =>
      (widget.myProfile['system_lang'] ?? 'fr') != (widget.contact['system_lang'] ?? 'en');

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _startCall();
    _registerWsHandlers();
  }

  Future<void> _startCall() async {
    // Demander les permissions micro (et caméra si appel vidéo)
    final granted = await PermissionService.requestCallPermissions(video: widget.isVideoCall);
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Permission micro refusée. Impossible de passer l'appel."),
        backgroundColor: Colors.red));
      Navigator.pop(context);
      return;
    }
    try {
      final res = await ApiService.startCall(widget.contact['id']);
      _callId = res['call_id'];
    } catch (_) {}
    WebSocketService.instance.sendCallRequest(widget.contact['id'], {
      'caller_name': _contactName,
      'is_video': widget.isVideoCall,
      'my_lang': widget.myProfile['system_lang'] ?? 'fr',
      'my_voice_model': widget.myProfile['voice_model_id'],
    });
    setState(() => _callStatus = 'Sonnerie...');
  }

  void _registerWsHandlers() {
    WebSocketService.instance.on('call_accepted', _onCallAccepted);
    WebSocketService.instance.on('call_rejected', _onCallRejected);
    WebSocketService.instance.on('call_ended', _onRemoteHangUp);
  }

  void _onCallAccepted(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _callAnswered = true;
      _callStatus = 'Connecté';
      _wasTranslated = _isTranslationActive && _langsDiffer;
      _cloneRatio = _wasTranslated ? 0.88 : 0.0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _durationSeconds++);
    });
  }

  void _onCallRejected(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() => _callStatus = 'Appel refusé');
    Future.delayed(const Duration(seconds: 2), _endCall);
  }

  void _onRemoteHangUp(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() => _callStatus = 'Appel terminé');
    _endCall();
  }

  Future<void> _endCall() async {
    if (_callEnded) return;
    _callEnded = true;
    _timer?.cancel();
    WebSocketService.instance.sendCallEnded(widget.contact['id']);
    if (_callId != null) {
      await ApiService.endCall(_callId!, _durationSeconds, _wasTranslated, _cloneRatio);
    }
    if (mounted) Navigator.pop(context);
  }

  String _formatDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(
                onTap: () => setState(() => _isTranslationActive = !_isTranslationActive),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isTranslationActive ? const Color(0xFFFF6B00).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isTranslationActive ? const Color(0xFFFF6B00) : Colors.white24),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.translate, size: 12, color: _isTranslationActive ? const Color(0xFFFF6B00) : Colors.grey),
                    const SizedBox(width: 4),
                    Text(_isTranslationActive ? 'VoxLink AI ON' : 'VoxLink AI OFF',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: _isTranslationActive ? const Color(0xFFFF6B00) : Colors.grey)),
                  ]),
                ),
              ),
              Text(widget.isVideoCall ? '📹 Vidéo' : '📞 Voix',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
          const Spacer(),
          // Avatar + status
          ScaleTransition(
            scale: _callAnswered ? const AlwaysStoppedAnimation(1.0) : _pulseAnim,
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.indigo.withOpacity(0.7),
              child: Text(_contactInitials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          Text(_contactName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_callAnswered ? _formatDuration(_durationSeconds) : _callStatus,
              style: TextStyle(color: _callAnswered ? const Color(0xFFFF6B00) : Colors.grey, fontSize: 14)),
          const SizedBox(height: 32),
          // AI Status card
          if (_langsDiffer)
            AnimatedOpacity(
              opacity: _isTranslationActive ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 300),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.security, color: _isTranslationActive ? Colors.greenAccent : Colors.grey, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      _isTranslationActive
                          ? _callAnswered ? 'Traduction vocale active — voix clonée à ${(_cloneRatio * 100).toInt()}%' : 'Prêt à traduire & cloner votre voix'
                          : 'Traduction désactivée — voix brute',
                      style: TextStyle(color: _isTranslationActive ? Colors.greenAccent : Colors.grey, fontSize: 11),
                    )),
                  ]),
                  if (_callAnswered && _isTranslationActive) ...[
                    const Divider(color: Colors.white10, height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${(widget.myProfile['system_lang'] ?? 'FR').toUpperCase()} → ${(widget.contact['system_lang'] ?? 'EN').toUpperCase()}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      Text('Fidélité vocale : ${(_cloneRatio * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ]),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Icon(Icons.flash_on, color: Color(0xFFFF6B00), size: 14),
                SizedBox(width: 8),
                Expanded(child: Text('Même langue détectée — latence 0ms, voix pure.', style: TextStyle(color: Color(0xFFFF6B00), fontSize: 11))),
              ]),
            ),
          const Spacer(),
          // Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _controlBtn(Icons.mic_off, _isMuted, () => setState(() => _isMuted = !_isMuted), label: _isMuted ? 'Muet' : 'Micro'),
              GestureDetector(
                onTap: _endCall,
                child: const CircleAvatar(radius: 34, backgroundColor: Colors.redAccent,
                    child: Icon(Icons.call_end, color: Colors.white, size: 28)),
              ),
              _controlBtn(Icons.volume_up, _isSpeakerOn, () => setState(() => _isSpeakerOn = !_isSpeakerOn), label: 'Haut-parleur'),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _controlBtn(IconData icon, bool active, VoidCallback onTap, {String? label}) => Column(mainAxisSize: MainAxisSize.min, children: [
    GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 26,
        backgroundColor: active ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.07),
        child: Icon(icon, color: active ? Colors.white : Colors.white54, size: 20),
      ),
    ),
    if (label != null) ...[const SizedBox(height: 6), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9))],
  ]);

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    WebSocketService.instance.off('call_accepted', _onCallAccepted);
    WebSocketService.instance.off('call_rejected', _onCallRejected);
    WebSocketService.instance.off('call_ended', _onRemoteHangUp);
    super.dispose();
  }
}

// ── Incoming call overlay ──────────────────────────────────────────────────────
class IncomingCallOverlay extends StatelessWidget {
  final Map<String, dynamic> callerPayload;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const IncomingCallOverlay({super.key, required this.callerPayload, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final from = callerPayload['from'] ?? 'Inconnu';
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.call_incoming, color: Color(0xFFFF6B00), size: 40),
          const SizedBox(height: 12),
          Text('Appel entrant de $from', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            GestureDetector(onTap: onReject,
              child: const CircleAvatar(radius: 28, backgroundColor: Colors.redAccent, child: Icon(Icons.call_end, color: Colors.white))),
            GestureDetector(onTap: onAccept,
              child: const CircleAvatar(radius: 28, backgroundColor: Colors.green, child: Icon(Icons.call, color: Colors.white))),
          ]),
        ]),
      ),
    );
  }
}
