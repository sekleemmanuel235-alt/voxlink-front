class UserModel {
  final String id;
  final String? username;
  final String? fullname;
  final String? bio;
  final String? avatarUrl;
  final String systemLang;
  final bool isVerified;
  final bool isPremium;
  final bool isOnline;
  final String? voiceModelId;
  final String? premiumUntil;

  UserModel({
    required this.id,
    this.username,
    this.fullname,
    this.bio,
    this.avatarUrl,
    this.systemLang = 'fr',
    this.isVerified = false,
    this.isPremium = false,
    this.isOnline = false,
    this.voiceModelId,
    this.premiumUntil,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] ?? '',
    username: j['username'],
    fullname: j['fullname'],
    bio: j['bio'],
    avatarUrl: j['avatar_url'],
    systemLang: j['system_lang'] ?? 'fr',
    isVerified: j['is_verified'] == true,
    isPremium: j['is_premium'] == true,
    isOnline: j['is_online'] == true,
    voiceModelId: j['voice_model_id'],
    premiumUntil: j['premium_until'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'username': username, 'fullname': fullname,
    'bio': bio, 'avatar_url': avatarUrl, 'system_lang': systemLang,
    'is_verified': isVerified, 'is_premium': isPremium,
    'is_online': isOnline, 'voice_model_id': voiceModelId,
  };

  String get displayName => (fullname?.isNotEmpty == true) ? fullname! : '@${username ?? id}';
  String get initials {
    final n = displayName.replaceAll('@', '');
    final parts = n.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n.toUpperCase();
  }
}
