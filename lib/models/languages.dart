/// VoxLink — Référentiel de langues supportées
/// 
/// AUCUNE LIMITE DE LANGUE : OpenRouter (LLaMA-3 70B) comprend et traduit
/// toutes les langues du monde qui ont une représentation textuelle.
/// Le prompt est libre : si une langue existe, elle est traduite.
/// 
/// Cette liste UI contient les 30 langues les plus parlées.
/// La traduction fonctionne également pour des langues hors liste
/// (créole, dialectes régionaux, langues rares) via le moteur LLM.

class AppLanguage {
  final String code;
  final String flag;
  final String label;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.flag,
    required this.label,
    required this.nativeName,
  });

  Map<String, String> toMap() => {'code': code, 'flag': flag, 'label': label};
}

/// Les 30 langues les plus parlées dans le monde — toutes supportées par VoxLink AI
const List<AppLanguage> kSupportedLanguages = [
  AppLanguage(code: 'zh', flag: '🇨🇳', label: 'Chinois',       nativeName: '中文'),
  AppLanguage(code: 'es', flag: '🇪🇸', label: 'Espagnol',       nativeName: 'Español'),
  AppLanguage(code: 'en', flag: '🇬🇧', label: 'Anglais',        nativeName: 'English'),
  AppLanguage(code: 'hi', flag: '🇮🇳', label: 'Hindi',          nativeName: 'हिन्दी'),
  AppLanguage(code: 'ar', flag: '🇸🇦', label: 'Arabe',          nativeName: 'العربية'),
  AppLanguage(code: 'pt', flag: '🇧🇷', label: 'Portugais',      nativeName: 'Português'),
  AppLanguage(code: 'bn', flag: '🇧🇩', label: 'Bengali',        nativeName: 'বাংলা'),
  AppLanguage(code: 'ru', flag: '🇷🇺', label: 'Russe',          nativeName: 'Русский'),
  AppLanguage(code: 'ja', flag: '🇯🇵', label: 'Japonais',       nativeName: '日本語'),
  AppLanguage(code: 'de', flag: '🇩🇪', label: 'Allemand',       nativeName: 'Deutsch'),
  AppLanguage(code: 'fr', flag: '🇫🇷', label: 'Français',       nativeName: 'Français'),
  AppLanguage(code: 'ko', flag: '🇰🇷', label: 'Coréen',         nativeName: '한국어'),
  AppLanguage(code: 'tr', flag: '🇹🇷', label: 'Turc',           nativeName: 'Türkçe'),
  AppLanguage(code: 'it', flag: '🇮🇹', label: 'Italien',        nativeName: 'Italiano'),
  AppLanguage(code: 'pl', flag: '🇵🇱', label: 'Polonais',       nativeName: 'Polski'),
  AppLanguage(code: 'nl', flag: '🇳🇱', label: 'Néerlandais',    nativeName: 'Nederlands'),
  AppLanguage(code: 'fa', flag: '🇮🇷', label: 'Persan',         nativeName: 'فارسی'),
  AppLanguage(code: 'vi', flag: '🇻🇳', label: 'Vietnamien',     nativeName: 'Tiếng Việt'),
  AppLanguage(code: 'th', flag: '🇹🇭', label: 'Thaï',           nativeName: 'ภาษาไทย'),
  AppLanguage(code: 'uk', flag: '🇺🇦', label: 'Ukrainien',      nativeName: 'Українська'),
  AppLanguage(code: 'ms', flag: '🇲🇾', label: 'Malais',         nativeName: 'Bahasa Melayu'),
  AppLanguage(code: 'id', flag: '🇮🇩', label: 'Indonésien',     nativeName: 'Bahasa Indonesia'),
  AppLanguage(code: 'ro', flag: '🇷🇴', label: 'Roumain',        nativeName: 'Română'),
  AppLanguage(code: 'el', flag: '🇬🇷', label: 'Grec',           nativeName: 'Ελληνικά'),
  AppLanguage(code: 'cs', flag: '🇨🇿', label: 'Tchèque',        nativeName: 'Čeština'),
  AppLanguage(code: 'hu', flag: '🇭🇺', label: 'Hongrois',       nativeName: 'Magyar'),
  AppLanguage(code: 'sv', flag: '🇸🇪', label: 'Suédois',        nativeName: 'Svenska'),
  AppLanguage(code: 'he', flag: '🇮🇱', label: 'Hébreu',         nativeName: 'עברית'),
  AppLanguage(code: 'sw', flag: '🇰🇪', label: 'Swahili',        nativeName: 'Kiswahili'),
  AppLanguage(code: 'tl', flag: '🇵🇭', label: 'Tagalog',        nativeName: 'Filipino'),
];

/// Trouve une langue par son code ISO
AppLanguage? findLanguage(String code) {
  try {
    return kSupportedLanguages.firstWhere((l) => l.code == code);
  } catch (_) { return null; }
}
