import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../widgets/language_picker.dart';
import '../services/permission_service.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingView({super.key, required this.onComplete});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pages = PageController();
  int _page = 0;
  bool _loading = false;
  String? _error;

  final _contactCtrl  = TextEditingController();
  final _usernameCtrl = TextEditingController();
  String _selectedLang = 'fr';

  Future<void> _register() async {
    if (_contactCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Entrez votre email ou numéro de téléphone.'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // Vrai device ID matériel via device_info_plus
      final deviceId = await DeviceService.getDeviceId();
      // Demander permissions micro en avance (non-bloquant)
      await PermissionService.requestMicrophonePermission();

      final res = await ApiService.register(
        deviceId: deviceId,
        contact: _contactCtrl.text.trim(),
        systemLang: _selectedLang,
        username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
      );
      if (res['token'] != null) {
        widget.onComplete();
      } else {
        setState(() => _error = res['detail'] ?? 'Erreur d\'inscription.');
      }
    } catch (e) {
      setState(() => _error = 'Impossible de joindre le serveur. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() => _pages.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0C),
      body: SafeArea(child: Column(children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(children: List.generate(3, (i) => Expanded(child: Container(
            height: 3, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i <= _page ? const Color(0xFFFF6B00) : Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          )))),
        ),
        Expanded(child: PageView(
          controller: _pages,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _page = i),
          children: [_page1(), _page2(), _page3()],
        )),
      ])),
    );
  }

  Widget _page1() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(children: [
      const SizedBox(height: 32),
      const Text('VoxLink', style: TextStyle(color: Color(0xFFFF6B00), fontSize: 46, fontWeight: FontWeight.w900, letterSpacing: -1)),
      const Text('by VoxLink AI', style: TextStyle(color: Colors.grey, fontSize: 13, letterSpacing: 3)),
      const SizedBox(height: 56),
      _feat(Icons.translate, 'Parlez votre langue', 'Messages et appels traduits en temps réel, automatiquement.'),
      const SizedBox(height: 24),
      _feat(Icons.record_voice_over, 'Votre voix, toutes les langues', 'Clonage vocal : vos interlocuteurs vous entendent AVEC votre voix, traduite. Imperceptible.'),
      const SizedBox(height: 24),
      _feat(Icons.bolt, 'Latence < 300ms', 'La traduction est invisible. Comme parler la même langue.'),
      const Spacer(),
      _btn('Commencer', _next),
    ]),
  );

  Widget _page2() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(children: [
      const Spacer(),
      const Icon(Icons.language, color: Color(0xFFFF6B00), size: 64),
      const SizedBox(height: 24),
      const Text('Votre langue', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      const Text('VoxLink traduit tout automatiquement pour vous et dans le sens inverse pour vos contacts.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
      const SizedBox(height: 32),
      LanguagePicker(
        selectedCode: _selectedLang,
        label: 'Langue principale',
        onSelected: (code) => setState(() => _selectedLang = code),
      ),
      const Spacer(),
      _btn('Continuer', _next),
    ]),
  );

  Widget _page3() => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(children: [
      const SizedBox(height: 48),
      const Icon(Icons.person_add_outlined, color: Color(0xFFFF6B00), size: 64),
      const SizedBox(height: 24),
      const Text('Créer votre compte', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Gratuit. Aucune carte bancaire requise.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 28),
      _field(_contactCtrl, 'Email ou téléphone *', Icons.alternate_email),
      const SizedBox(height: 14),
      _field(_usernameCtrl, "Nom d'utilisateur (optionnel)", Icons.badge_outlined),
      if (_error != null) Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
          ]),
        ),
      ),
      const SizedBox(height: 28),
      _loading
          ? const CircularProgressIndicator(color: Color(0xFFFF6B00))
          : _btn("C'est parti !", _register),
      const SizedBox(height: 16),
      const Text('En continuant vous acceptez nos CGU et notre Politique de confidentialité.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10, height: 1.4)),
      const SizedBox(height: 24),
    ]),
  );

  Widget _feat(IconData icon, String t, String s) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFFF6B00).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: const Color(0xFFFF6B00), size: 22)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(s, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
      ])),
    ],
  );

  Widget _field(TextEditingController c, String hint, IconData icon) => TextField(
    controller: c, style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true, fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
  );

  Widget _btn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 54,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );

  @override
  void dispose() { _contactCtrl.dispose(); _usernameCtrl.dispose(); super.dispose(); }
}
