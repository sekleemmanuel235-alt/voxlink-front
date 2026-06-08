class MessageModel {
  final String id;
  final String senderId;
  final String originalText;
  final String? translatedText;
  final bool isTranslated;
  final bool isRead;
  final String createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.originalText,
    this.translatedText,
    this.isTranslated = false,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
    id: j['id'] ?? '',
    senderId: j['sender_id'] ?? '',
    originalText: j['original_text'] ?? '',
    translatedText: j['translated_text'],
    isTranslated: j['is_translated'] == true,
    isRead: j['is_read'] == true,
    createdAt: j['created_at']?.toString() ?? '',
  );

  String displayText(String myUserId) =>
      senderId == myUserId ? originalText : (translatedText ?? originalText);
}
