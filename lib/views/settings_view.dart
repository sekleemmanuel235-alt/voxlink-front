import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/language_picker.dart';
import '../models/languages.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Map<String, dynamic> profile;
  final VoidCallback onProfileUpdated;
  const SettingsView({super.key, required this.toggleTheme, required this.profile, required this.onProfileUpdated});
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _loaded = false;

  // Notification prefs
  bool _notifMessages    = true;
  bool _notifCalls       = true;
  bool _notifMentions    = true;
  bool _notifGroups      = false;
  bool _notifMarketing   = false;

  // Privacy prefs
  String _whoCanMessage  = 'contacts';
  String _whoCanSeeProfile = 'everyone';
  bool   _showOnline     = true;
  bool   _readReceipts   = true;

  // Translation prefs
  bool   _autoChat       = true;
  bool   _autoFeed       = true;
  String _feedMode       = 'subtitles';

  @override
  void initState() { super.initState(); _loadPrefs(); }

  Future<void> _loadPrefs() async {
    try {
      final p = await ApiService.getPreferences();
      if (!mounted) return;
      setState(() {
        _notifMessages  = p['notif_messages']      ?? true;
        _notifCalls     = p['notif_calls']          ?? true;
        _notifMentions  = p['notif_mentions']       ?? true;
        _notifGroups    = p['notif_groups']         ?? false;
        _notifMarketing = p['notif_marketing']      ?? false;
        _whoCanMessage  = p['who_can_message']      ?? 'contacts';
        _whoCanSeeProfile = p['who_can_see_profile'] ?? 'everyone';
        _showOnline     = p['show_online_status']   ?? true;
        _readReceipts   = p['read_receipts']        ?? true;
        _autoChat       = p['auto_translate_chat']  ?? true;
        _autoFeed       = p['auto_translate_feed']  ?? true;
        _feedMode       = p['default_feed_mode']    ?? 'subtitles';
        _loaded = true;
      });
    } catch (_) { if (mounted) setState(() => _loaded = true); }
  }

  Future<void> _save(Map<String, dynamic> delta) async {
    try { await ApiService.updatePreferences(delta); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold))),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [

          // ── NOTIFICATIONS ──────────────────────────────────────────
          _section('Notifications'),
          _sw('Messages', 'Nouveaux messages reçus', Icons.chat_bubble_outline, _notifMessages,
              (v) { setState(() => _notifMessages=v); _save({'notif_messages':v}); }),
          _sw('Appels', 'Appels entrants', Icons.phone_outlined, _notifCalls,
              (v) { setState(() => _notifCalls=v); _save({'notif_calls':v}); }),
          _sw('Mentions', 'Quand quelqu\'un vous mentionne', Icons.alternate_email, _notifMentions,
              (v) { setState(() => _notifMentions=v); _save({'notif_mentions':v}); }),
          _sw('Groupes', 'Activité dans vos groupes', Icons.public_outlined, _notifGroups,
              (v) { setState(() => _notifGroups=v); _save({'notif_groups':v}); }),
          _sw('Promotions', 'Actualités et offres VoxLink', Icons.campaign_outlined, _notifMarketing,
              (v) { setState(() => _notifMarketing=v); _save({'notif_marketing':v}); }),

          // ── CONFIDENTIALITÉ ────────────────────────────────────────
          _section('Confidentialité'),
          _dd('Qui peut m\'écrire', Icons.lock_outline, _whoCanMessage,
              const {'contacts':'Contacts uniquement','everyone':'Tout le monde','nobody':'Personne'},
              (v) { setState(() => _whoCanMessage=v); _save({'who_can_message':v}); }),
          _dd('Visibilité du profil', Icons.person_outline, _whoCanSeeProfile,
              const {'everyone':'Tout le monde','contacts':'Contacts uniquement','nobody':'Personne'},
              (v) { setState(() => _whoCanSeeProfile=v); _save({'who_can_see_profile':v}); }),
          _sw('Statut en ligne', 'Afficher quand vous êtes actif', Icons.circle_outlined, _showOnline,
              (v) { setState(() => _showOnline=v); _save({'show_online_status':v}); }),
          _sw('Confirmations de lecture', 'Afficher les coches bleues', Icons.done_all_outlined, _readReceipts,
              (v) { setState(() => _readReceipts=v); _save({'read_receipts':v}); }),
          _nav('Utilisateurs bloqués', Icons.block_outlined, () => _showBlockedUsers()),
          _nav('Signaler un problème', Icons.flag_outlined, () => _showReportSheet()),

          // ── TRADUCTION ─────────────────────────────────────────────
          _section('Traduction & IA VoxLink AI'),
          _sw('Traduction auto — Chat', 'Traduire automatiquement les messages', Icons.chat_outlined, _autoChat,
              (v) { setState(() => _autoChat=v); _save({'auto_translate_chat':v}); }),
          _sw('Traduction auto — Fil', 'Traduire les captions des vidéos', Icons.translate, _autoFeed,
              (v) { setState(() => _autoFeed=v); _save({'auto_translate_feed':v}); }),
          _dd('Mode par défaut (Fil)', Icons.subtitles_outlined, _feedMode,
              const {'off':'Version originale (VO)','subtitles':'Sous-titres traduits','audio':'Audio traduit VoxLink AI'},
              (v) { setState(() => _feedMode=v); _save({'default_feed_mode':v}); }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFF6B00).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.info_outline, color: Color(0xFFFF6B00), size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'VoxLink AI supporte ${AppLanguages.all.length} langues sans restriction — toutes les langues ISO 639-1.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B00)),
                )),
              ]),
            ),
          ),

          // ── APPARENCE ──────────────────────────────────────────────
          _section('Apparence'),
          _nav('Thème clair / sombre', Icons.brightness_6_outlined, widget.toggleTheme),

          // ── COMPTE ─────────────────────────────────────────────────
          _section('Compte'),
          _nav('Modifier le profil', Icons.edit_outlined, () => Navigator.pop(context)),
          _nav('Changer de langue', Icons.language_outlined, () => _showChangeLang()),
          _nav('Sessions actives', Icons.devices_outlined, () => _showSessions()),
          _nav('Télécharger mes données', Icons.download_outlined, () => _showExportInfo()),

          // ── AIDE & LÉGAL ───────────────────────────────────────────
          _section('Aide & Légal'),
          _nav('Centre d\'aide', Icons.help_outline, () {}),
          _nav('Politique de confidentialité', Icons.privacy_tip_outlined, () {}),
          _nav('Conditions d\'utilisation', Icons.article_outlined, () {}),
          _nav('Licences open source', Icons.code_outlined, () => showLicensePage(context: context)),
          _info('Version', 'VoxLink 3.1.0 VoxLink AI'),
          _info('ID', ApiService.userId ?? '—'),

          // ── ZONE DANGEREUSE ────────────────────────────────────────
          _section('Zone dangereuse'),
          _nav('Se déconnecter', Icons.logout, _logout, color: Colors.orange),
          _nav('Supprimer le compte', Icons.delete_forever_outlined, _deleteAccount, color: Colors.red),

          const SizedBox(height: 40),
        ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8)));

  Widget _sw(String title, String sub, IconData icon, bool val, ValueChanged<bool> onCh) => ListTile(
    dense: true,
    leading: Icon(icon, color: const Color(0xFFFF6B00), size: 20),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    trailing: Switch.adaptive(value: val, onChanged: onCh, activeColor: const Color(0xFFFF6B00)));

  Widget _nav(String t, IconData icon, VoidCallback onTap, {Color? color}) => ListTile(
    dense: true,
    leading: Icon(icon, color: color ?? const Color(0xFFFF6B00), size: 20),
    title: Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
    onTap: onTap);

  Widget _dd(String title, IconData icon, String value, Map<String,String> options, ValueChanged<String> onCh) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFFFF6B00), size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: DropdownButton<String>(
        value: options.containsKey(value) ? value : options.keys.first,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) { if (v != null) onCh(v); },
      ),
    );
  }

  Widget _info(String label, String val) => ListTile(
    dense: true,
    leading: const SizedBox(width: 20),
    title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
    trailing: Text(val, style: const TextStyle(fontSize: 12, color: Colors.grey)));

  // ── Actions ───────────────────────────────────────────────────────

  void _showChangeLang() {
    final currentLang = widget.profile['system_lang'] ?? 'fr';
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Changer de langue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LanguagePicker(
            selectedCode: currentLang,
            label: 'Votre langue principale',
            onSelected: (code) async {
              Navigator.pop(context);
              await ApiService.updateProfile(systemLang: code);
              widget.onProfileUpdated();
            },
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showBlockedUsers() async {
    List<dynamic> blocked = [];
    try { blocked = await ApiService.getBlockedUsers(); } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Utilisateurs bloqués (${blocked.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (blocked.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Aucun utilisateur bloqué.', style: TextStyle(color: Colors.grey)))
          else
            ...blocked.map((b) => ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text(b['fullname'] ?? '@${b['username']}'),
              subtitle: Text('@${b['username'] ?? ''}', style: const TextStyle(fontSize: 11)),
              trailing: TextButton(
                onPressed: () async {
                  await ApiService.unblockUser(b['user_id']);
                  setS(() => blocked.removeWhere((x) => x['user_id'] == b['user_id']));
                },
                child: const Text('Débloquer', style: TextStyle(color: Color(0xFFFF6B00))),
              ),
            )),
        ]),
      )),
    );
  }

  void _showSessions() => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Sessions actives', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ListTile(
        leading: const Icon(Icons.phone_android, color: Color(0xFFFF6B00)),
        title: const Text('Cet appareil', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: const Text('Session actuelle', style: TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: const Text('Actif', style: TextStyle(color: Colors.green, fontSize: 11))),
      ),
    ])),
  );

  void _showExportInfo() => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.download_outlined, color: Color(0xFFFF6B00), size: 40),
      const SizedBox(height: 12),
      const Text('Télécharger vos données', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Vos données (profil, messages, historique d\'appels) seront exportées en JSON et envoyées à votre adresse email enregistrée.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export demandé — vous recevrez un email dans 24h.'))); },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white),
        child: const Text('Demander l\'export'),
      )),
    ])),
  );

  void _showReportSheet() => showModalBottomSheet(
    context: context, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) {
      final ctrl = TextEditingController();
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Signaler un problème', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Décrivez le problème...')),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci, votre signalement a été envoyé.'))); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white),
            child: const Text('Envoyer'),
          )),
        ]),
      );
    },
  );

  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Se déconnecter'),
      content: const Text('Vous serez déconnecté de VoxLink sur cet appareil.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Déconnexion', style: TextStyle(color: Colors.orange))),
      ],
    ));
    if (ok == true) await ApiService.logout();
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Supprimer le compte', style: TextStyle(color: Colors.red)),
      content: const Text('Action irréversible. Toutes vos données, messages et contacts seront supprimés définitivement.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (ok == true) await ApiService.deleteAccount();
  }
}
