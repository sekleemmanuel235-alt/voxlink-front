import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/api_service.dart';
import '../services/voice_recorder_service.dart';
import '../services/permission_service.dart';
import '../widgets/user_avatar.dart';
import '../models/user_model.dart';
import 'settings_view.dart';

const String _rcEntitlement = "premium";

class ProfileView extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Map<String, dynamic> profile;
  final VoidCallback onProfileUpdated;
  const ProfileView({super.key, required this.toggleTheme, required this.profile, required this.onProfileUpdated});
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late UserModel _user;
  bool _loadingPurchase = false;

  final _langs = [
    {'code':'fr','flag':'🇫🇷','label':'Français'},{'code':'en','flag':'🇬🇧','label':'English'},
    {'code':'es','flag':'🇪🇸','label':'Español'},{'code':'pt','flag':'🇧🇷','label':'Português'},
    {'code':'de','flag':'🇩🇪','label':'Deutsch'},{'code':'ar','flag':'🇸🇦','label':'العربية'},
    {'code':'zh','flag':'🇨🇳','label':'中文'},{'code':'ja','flag':'🇯🇵','label':'日本語'},
    {'code':'ko','flag':'🇰🇷','label':'한국어'},{'code':'it','flag':'🇮🇹','label':'Italiano'},
    {'code':'ru','flag':'🇷🇺','label':'Русский'},{'code':'nl','flag':'🇳🇱','label':'Nederlands'},
  ];

  @override
  void initState() { super.initState(); _user = UserModel.fromJson(widget.profile); }
  @override
  void didUpdateWidget(ProfileView old) {
    super.didUpdateWidget(old);
    if (widget.profile != old.profile) setState(() => _user = UserModel.fromJson(widget.profile));
  }

  String get _langFlag => _langs.firstWhere((l)=>l['code']==_user.systemLang, orElse:()=>{'flag':'🌍'})['flag']!;
  String get _langLabel => _langs.firstWhere((l)=>l['code']==_user.systemLang, orElse:()=>{'label':'?'})['label']!;

  // ── RevenueCat purchase flow ───────────────────────────────────────
  Future<void> _purchasePremium(Package package) async {
    setState(() => _loadingPurchase = true);
    try {
      final result = await Purchases.purchasePackage(package);
      final isPremium = result.entitlements.active.containsKey(_rcEntitlement);
      if (isPremium) {
        // Valider côté serveur VoxLink
        await ApiService.verifyPremium(result.originalAppUserId);
        widget.onProfileUpdated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🎉 Bienvenue dans VoxLink Premium !'),
            backgroundColor: Color(0xFFFF6B00)));
        }
      }
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur achat : ${e.name}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => _loadingPurchase = false); }
  }

  Future<void> _restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      final isPremium = info.entitlements.active.containsKey(_rcEntitlement);
      if (isPremium) {
        await ApiService.verifyPremium(info.originalAppUserId);
        widget.onProfileUpdated();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achats restaurés ✓'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun achat Premium trouvé.')));
      }
    } catch (_) {}
  }

  void _showPremiumSheet() async {
    Offerings? offerings;
    try { offerings = await Purchases.getOfferings(); } catch (_) {}

    if (!mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star, color: Color(0xFFFF6B00), size: 48),
          const SizedBox(height: 12),
          const Text('VoxLink Premium', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Débloquez tout le potentiel de VoxLink.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          _premiumRow(Icons.record_voice_over, 'Clonage vocal', 'Votre voix traduite — imperceptible.'),
          _premiumRow(Icons.hd, 'Appels HD 1080p', 'Qualité maximale.'),
          _premiumRow(Icons.all_inclusive, 'Traductions illimitées', 'Toutes les langues du monde.'),
          _premiumRow(Icons.subtitles, 'Audio traduit sur vidéos', 'Mode audio VoxLink AI activé.'),
          _premiumRow(Icons.verified, 'Badge Premium', 'Profil mis en avant.'),
          const SizedBox(height: 20),
          if (offerings != null && offerings.current != null) ...[
            // Monthly offer
            if (offerings.current!.monthly != null)
              _offerButton(offerings.current!.monthly!, 'Mensuel', setS),
            const SizedBox(height: 10),
            // Annual offer (best value)
            if (offerings.current!.annual != null)
              _offerButton(offerings.current!.annual!, 'Annuel — Meilleur prix', setS, highlight: true),
          ] else ...[
            // Fallback si pas de connexion RevenueCat
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Text('Connectez votre compte RevenueCat pour activer les achats.\nVoir DEPLOYMENT_GUIDE.md',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(onPressed: _restorePurchases, child: const Text('Restaurer mes achats', style: TextStyle(color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 8),
          const Text('L\'abonnement se renouvelle automatiquement. Annulable à tout moment.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 16),
        ]),
      )),
    );
  }

  Widget _offerButton(Package pkg, String label, StateSetter setS, {bool highlight = false}) {
    final price = pkg.storeProduct.priceString;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loadingPurchase ? null : () async {
          setS(() {});
          await _purchasePremium(pkg);
          setS(() {});
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: highlight ? const Color(0xFFFF6B00) : Colors.grey[200],
          foregroundColor: highlight ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loadingPurchase
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text('$label — $price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _premiumRow(IconData icon, String t, String s) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, color: const Color(0xFFFF6B00), size: 20), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Text(s, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ])),
    ]),
  );

  void _showEditSheet() {
    final fnCtrl  = TextEditingController(text: _user.fullname ?? '');
    final bioCtrl = TextEditingController(text: _user.bio ?? '');
    final unCtrl  = TextEditingController(text: _user.username ?? '');
    String lang   = _user.systemLang;
    String? err;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Modifier le profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          TextField(controller: fnCtrl, decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline, size: 18))),
          const SizedBox(height: 12),
          TextField(controller: unCtrl, decoration: const InputDecoration(labelText: "Nom d'utilisateur", prefixIcon: Icon(Icons.alternate_email, size: 18))),
          const SizedBox(height: 12),
          TextField(controller: bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.edit_note, size: 18))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: lang,
            decoration: const InputDecoration(labelText: 'Langue principale', prefixIcon: Icon(Icons.language, size: 18)),
            items: _langs.map((l) => DropdownMenuItem(value: l['code']!, child: Text('${l['flag']} ${l['label']}'))).toList(),
            onChanged: (v) { if (v != null) setS(() => lang = v); },
          ),
          if (err != null) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(err!, style: const TextStyle(color: Colors.red, fontSize: 12))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.updateProfile(fullname: fnCtrl.text.trim(), bio: bioCtrl.text.trim(),
                    username: unCtrl.text.trim().isEmpty ? null : unCtrl.text.trim(), systemLang: lang);
                Navigator.pop(context); widget.onProfileUpdated();
              } catch (_) { setS(() => err = 'Erreur lors de la sauvegarde.'); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      )),
    );
  }

  void _showVoiceSheet() {
    bool isRecording = false;
    bool isDone = false;
    bool uploading = false;
    String status = "Appuyez pour commencer (min. 30 secondes)";
    showModalBottomSheet(
      context: context, isScrollControlled: true, isDismissible: !isRecording,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isRecording ? Icons.graphic_eq : (isDone ? Icons.check_circle : Icons.mic),
              color: isRecording ? Colors.redAccent : (isDone ? Colors.green : const Color(0xFFFF6B00)), size: 48),
          const SizedBox(height: 12),
          Text(uploading ? 'Envoi à ElevenLabs...' : (isDone ? 'Clonage réussi ✓' : 'Cloner votre voix'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFF6B00).withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
            child: const Text('• Parlez naturellement pendant 30 secondes\n• Lisez un texte ou improvisez\n• Évitez les bruits de fond\n• Voix claire et normale',
                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.6))),
          const SizedBox(height: 20),
          if (!isDone && !uploading) SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () async {
              if (!isRecording) {
                final ok = await PermissionService.requestMicrophonePermission();
                if (!ok) { setS(() => status = "Permission micro refusée."); return; }
                await VoiceRecorderService.start();
                setS(() { isRecording = true; status = "Enregistrement... Parlez maintenant."; });
              } else {
                setS(() { isRecording = false; uploading = true; status = "Envoi en cours..."; });
                final bytes = await VoiceRecorderService.stop();
                if (bytes != null && bytes.isNotEmpty) {
                  try {
                    final res = await ApiService.uploadVoiceClone(bytes);
                    if (res['voice_model_id'] != null) {
                      setS(() { isDone = true; uploading = false; status = "Votre empreinte vocale est active sur VoxLink."; });
                      widget.onProfileUpdated();
                    } else {
                      setS(() { uploading = false; status = res['detail'] ?? "Erreur — réessayez."; });
                    }
                  } catch (_) { setS(() { uploading = false; status = "Erreur réseau — réessayez."; }); }
                } else { setS(() { uploading = false; status = "Enregistrement vide — réessayez."; }); }
              }
            },
            icon: uploading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : Icon(isRecording ? Icons.stop : Icons.mic),
            label: Text(isRecording ? 'Arrêter et envoyer' : 'Commencer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecording ? Colors.redAccent : const Color(0xFFFF6B00),
              foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          )),
          if (isDone) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            )),
          ],
          const SizedBox(height: 8),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Align(alignment: Alignment.centerRight, child: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
              SettingsView(toggleTheme: widget.toggleTheme, profile: widget.profile, onProfileUpdated: widget.onProfileUpdated))),
        )),
        Stack(alignment: Alignment.bottomRight, children: [
          UserAvatar(initials: _user.initials, radius: 48, isPremium: _user.isPremium),
          GestureDetector(onTap: _showEditSheet, child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFFF6B00), shape: BoxShape.circle,
                border: Border.all(color: isDark ? const Color(0xFF0B0B0C) : Colors.white, width: 2)),
            child: const Icon(Icons.edit, size: 12, color: Colors.white))),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(_user.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          if (_user.isVerified) ...[const SizedBox(width: 6), const Icon(Icons.verified, size: 18, color: Color(0xFF3797EF))],
        ]),
        if (_user.username != null) ...[
          const SizedBox(height: 2),
          Text('@${_user.username}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFFF6B00).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text('$_langFlag $_langLabel', style: const TextStyle(fontSize: 12, color: Color(0xFFFF6B00), fontWeight: FontWeight.w600))),
        if (_user.bio?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(_user.bio!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
        const SizedBox(height: 16),
        if (_user.isPremium)
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFF8C42)]), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star, color: Colors.white, size: 14), SizedBox(width: 6),
              Text('Membre Premium', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]))
        else
          GestureDetector(onTap: _showPremiumSheet,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFF6B00)), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_outline, color: Color(0xFFFF6B00), size: 14), SizedBox(width: 6),
                Text('Passer Premium', style: TextStyle(color: Color(0xFFFF6B00), fontSize: 12, fontWeight: FontWeight.bold)),
              ]))),
        const SizedBox(height: 24),
        Row(children: [
          _quick(Icons.edit_outlined, 'Modifier', _showEditSheet),
          const SizedBox(width: 10),
          _quick(Icons.settings_outlined, 'Paramètres', () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
              SettingsView(toggleTheme: widget.toggleTheme, profile: widget.profile, onProfileUpdated: widget.onProfileUpdated)))),
          const SizedBox(width: 10),
          _quick(_user.isPremium ? Icons.star : Icons.star_outline, 'Premium', _showPremiumSheet),
        ]),
        if (_user.isPremium) ...[
          const SizedBox(height: 10),
          GestureDetector(onTap: _showVoiceSheet, child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF8B3DFF).withOpacity(0.2), const Color(0xFFFF6B00).withOpacity(0.2)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B3DFF).withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.record_voice_over, color: Color(0xFF8B3DFF), size: 28), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_user.voiceModelId != null ? 'Voix clonée ✓' : 'Clonage vocal',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(_user.voiceModelId != null ? 'Empreinte vocale active' : 'Enregistrez votre voix (30s)',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ])),
              Icon(_user.voiceModelId != null ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: _user.voiceModelId != null ? Colors.green : Colors.grey, size: 16),
            ]),
          )),
        ],
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[100], borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _stat('0', 'Vidéos'),
            Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3)),
            _stat('0', 'Contacts'),
            Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3)),
            _stat(_user.isPremium ? '∞' : 'Limité', 'Traductions'),
          ])),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _quick(IconData icon, String label, VoidCallback onTap) => Expanded(
    child: GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: const Color(0xFFFF6B00), size: 22),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    )),
  );

  Widget _stat(String v, String l) => Column(children: [
    Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(l, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);
}
