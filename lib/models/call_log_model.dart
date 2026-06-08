class CallLogModel {
  final String callId;
  final String direction; // 'outgoing' | 'incoming'
  final Map<String, dynamic>? contact;
  final int durationSec;
  final bool wasTranslated;
  final double cloneRatio;
  final String startedAt;

  CallLogModel({
    required this.callId,
    required this.direction,
    this.contact,
    required this.durationSec,
    required this.wasTranslated,
    required this.cloneRatio,
    required this.startedAt,
  });

  factory CallLogModel.fromJson(Map<String, dynamic> j) => CallLogModel(
    callId: j['call_id'] ?? '',
    direction: j['direction'] ?? 'outgoing',
    contact: j['contact'],
    durationSec: j['duration_sec'] ?? 0,
    wasTranslated: j['was_translated'] == true,
    cloneRatio: (j['clone_ratio'] ?? 0.0).toDouble(),
    startedAt: j['started_at']?.toString() ?? '',
  );

  String get durationLabel {
    if (durationSec == 0) return 'Non répondu';
    final m = durationSec ~/ 60;
    final s = durationSec % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}
