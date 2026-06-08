import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String baseUrl = "http://10.0.2.2:8000"; // Override with your prod URL
  static String? _token;
  static String? _userId;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('voxlink_token');
    _userId = prefs.getString('voxlink_user_id');
    final savedUrl = prefs.getString('voxlink_backend_url');
    if (savedUrl != null) baseUrl = savedUrl;
  }

  static String? get token => _token;
  static String? get userId => _userId;
  static bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  static Future<void> _saveSession(String token, String userId) async {
    _token = token; _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voxlink_token', token);
    await prefs.setString('voxlink_user_id', userId);
  }

  static Future<void> clearSession() async {
    _token = null; _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('voxlink_token');
    await prefs.remove('voxlink_user_id');
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Auth ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String deviceId,
    String? contact,
    String systemLang = 'fr',
    String? username,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/v3/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId, 'contact': contact,
                        'system_lang': systemLang, 'username': username}),
    );
    final data = jsonDecode(r.body);
    if (r.statusCode == 200 || r.statusCode == 201) {
      await _saveSession(data['token'], data['user_id']);
    }
    return data;
  }

  static Future<void> logout() async {
    try {
      await http.post(Uri.parse('$baseUrl/api/v3/auth/logout'), headers: _headers);
    } catch (_) {}
    await clearSession();
  }

  // ── Profile ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyProfile() async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/profile/me'), headers: _headers);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? fullname, String? bio, String? username, String? systemLang,
  }) async {
    final r = await http.patch(
      Uri.parse('$baseUrl/api/v3/profile/update'), headers: _headers,
      body: jsonEncode({'fullname': fullname, 'bio': bio,
                        'username': username, 'system_lang': systemLang}),
    );
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> getProfileByUsername(String username) async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/profile/$username'), headers: _headers);
    return jsonDecode(r.body);
  }

  // ── Contacts ──────────────────────────────────────────────────────
  static Future<List<dynamic>> getContacts() async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/contacts'), headers: _headers);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> addContact(String username, {String? nickname}) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/v3/contacts/add'), headers: _headers,
      body: jsonEncode({'username': username, 'nickname': nickname}),
    );
    return jsonDecode(r.body);
  }

  static Future<void> removeContact(String contactId) async {
    await http.delete(Uri.parse('$baseUrl/api/v3/contacts/$contactId'), headers: _headers);
  }

  // ── Conversations ─────────────────────────────────────────────────
  static Future<List<dynamic>> getConversations() async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/conversations'), headers: _headers);
    return jsonDecode(r.body);
  }

  static Future<List<dynamic>> getMessages(String contactId) async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/conversations/$contactId/messages'), headers: _headers);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String toUserId, required String text, bool translationActive = true,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/v3/messages/send'), headers: _headers,
      body: jsonEncode({'to_user_id': toUserId, 'text': text, 'translation_active': translationActive}),
    );
    return jsonDecode(r.body);
  }

  // ── Calls ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> startCall(String calleeId) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/v3/calls/start'), headers: _headers,
      body: jsonEncode({'callee_id': calleeId}),
    );
    return jsonDecode(r.body);
  }

  static Future<void> endCall(String callId, int durationSec, bool wasTranslated, double cloneRatio) async {
    await http.post(
      Uri.parse('$baseUrl/api/v3/calls/end'), headers: _headers,
      body: jsonEncode({'call_id': callId, 'duration_sec': durationSec,
                        'was_translated': wasTranslated, 'clone_ratio': cloneRatio}),
    );
  }

  static Future<List<dynamic>> getCallHistory() async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/calls/history'), headers: _headers);
    return jsonDecode(r.body);
  }

  // ── Drafts ────────────────────────────────────────────────────────
  static Future<List<dynamic>> getDrafts() async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/drafts'), headers: _headers);
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> saveDraft(Map<String, dynamic> draft) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/v3/drafts'), headers: _headers, body: jsonEncode(draft),
    );
    return jsonDecode(r.body);
  }

  static Future<void> deleteDraft(int draftId) async {
    await http.delete(Uri.parse('$baseUrl/api/v3/drafts/$draftId'), headers: _headers);
  }

  // ── Premium (RevenueCat) ──────────────────────────────────────────
  static Future<Map<String, dynamic>> verifyPremium(String revenuecatUserId) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/v3/billing/verify-premium'), headers: _headers,
      body: jsonEncode({'revenuecat_user_id': revenuecatUserId, 'entitlement_id': 'premium'}),
    );
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> getBillingStatus() async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/billing/status'), headers: _headers);
    return jsonDecode(r.body);
  }

  // ── Search ────────────────────────────────────────────────────────
  static Future<List<dynamic>> searchUsers(String query) async {
    final r = await http.get(
      Uri.parse('$baseUrl/api/v3/search/users?q=${Uri.encodeComponent(query)}'), headers: _headers,
    );
    return jsonDecode(r.body);
  }

  // ── Presence ──────────────────────────────────────────────────────
  static Future<bool> getPresence(String userId) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/v3/presence/$userId'), headers: _headers);
      return jsonDecode(r.body)['is_online'] ?? false;
    } catch (_) { return false; }
  }
}

  // ── Voice clone upload ────────────────────────────────────────────
  static Future<Map<String, dynamic>> uploadVoiceClone(List<int> audioBytes) async {
    final uri = Uri.parse('$baseUrl/api/v3/voice/clone');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${_token ?? ""}'
      ..files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: 'voice_sample.wav'));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return jsonDecode(response.body);
  }

  // ── Preferences ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPreferences() async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/preferences'), headers: _headers);
    return jsonDecode(r.body);
  }

  static Future<void> updatePreferences(Map<String, dynamic> prefs) async {
    await http.patch(
      Uri.parse('$baseUrl/api/v3/preferences'), headers: _headers,
      body: jsonEncode(prefs),
    );
  }

  // ── Blocks ────────────────────────────────────────────────────────
  static Future<List<dynamic>> getBlockedUsers() async {
    final r = await http.get(Uri.parse('$baseUrl/api/v3/blocks'), headers: _headers);
    return jsonDecode(r.body);
  }

  static Future<void> blockUser(String userId) async {
    await http.post(
      Uri.parse('$baseUrl/api/v3/blocks'), headers: _headers,
      body: jsonEncode({'user_id': userId}),
    );
  }

  static Future<void> unblockUser(String userId) async {
    await http.delete(Uri.parse('$baseUrl/api/v3/blocks/$userId'), headers: _headers);
  }

  // ── Delete account ────────────────────────────────────────────────
  static Future<void> deleteAccount() async {
    try {
      await http.delete(Uri.parse('$baseUrl/api/v3/account'), headers: _headers);
    } catch (_) {}
    await clearSession();
  }
