import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

typedef WsHandler = void Function(Map<String, dynamic> data);

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  WebSocketService._();

  WebSocketChannel? _channel;
  final Map<String, List<WsHandler>> _handlers = {};
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect(String userId) {
    final wsUrl = ApiService.baseUrl.replaceAll('http', 'ws');
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws/v3/$userId'));
      _isConnected = true;
      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            final type = data['type'] as String? ?? '';
            _handlers[type]?.forEach((h) => h(data));
            _handlers['*']?.forEach((h) => h(data));
          } catch (e) { debugPrint('[WS parse error] $e'); }
        },
        onDone: () { _isConnected = false; debugPrint('[WS] Disconnected'); },
        onError: (e) { _isConnected = false; debugPrint('[WS error] $e'); },
      );
    } catch (e) { _isConnected = false; debugPrint('[WS connect error] $e'); }
  }

  void send(Map<String, dynamic> payload) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void on(String type, WsHandler handler) {
    _handlers.putIfAbsent(type, () => []).add(handler);
  }

  void off(String type, WsHandler handler) {
    _handlers[type]?.remove(handler);
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  // ── Shortcuts ─────────────────────────────────────────────────────
  void sendCallRequest(String toUserId, Map<String, dynamic> payload) =>
      send({'type': 'call_request', 'to': toUserId, 'payload': payload});

  void sendOffer(String toUserId, Map<String, dynamic> sdp) =>
      send({'type': 'offer', 'to': toUserId, 'payload': sdp});

  void sendAnswer(String toUserId, Map<String, dynamic> sdp) =>
      send({'type': 'answer', 'to': toUserId, 'payload': sdp});

  void sendIceCandidate(String toUserId, Map<String, dynamic> candidate) =>
      send({'type': 'ice_candidate', 'to': toUserId, 'payload': candidate});

  void sendCallAccepted(String toUserId) =>
      send({'type': 'call_accepted', 'to': toUserId, 'payload': {}});

  void sendCallRejected(String toUserId) =>
      send({'type': 'call_rejected', 'to': toUserId, 'payload': {}});

  void sendCallEnded(String toUserId) =>
      send({'type': 'call_ended', 'to': toUserId, 'payload': {}});

  void sendTypingStart(String toUserId) =>
      send({'type': 'typing_start', 'to': toUserId, 'payload': {}});

  void sendTypingStop(String toUserId) =>
      send({'type': 'typing_stop', 'to': toUserId, 'payload': {}});
}
