import 'dart:io';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/notification_service.dart';
import 'views/home_feed_view.dart';
import 'views/network_view.dart';
import 'views/calls_view.dart';
import 'views/chat_view.dart';
import 'views/groups_view.dart';
import 'views/profile_view.dart';
import 'views/onboarding_view.dart';

// ─── REVENUECAT — Remplacez par vos vraies clés publiques SDK ────────────────
// app.revenuecat.com → votre projet → API Keys → Public (iOS / Android)
const String _rcAppleKey   = "appl_VOTRE_CLE_PUBLIQUE_IOS";
const String _rcAndroidKey = "goog_VOTRE_CLE_PUBLIQUE_ANDROID";
const String _rcEntitlement = "premium"; // Nom exact de votre Entitlement RevenueCat

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  await NotificationService.init();
  await _initRevenueCat();
  runApp(const VoxLinkApp());
}

Future<void> _initRevenueCat() async {
  try {
    await Purchases.setLogLevel(LogLevel.error);
    final key = Platform.isIOS ? _rcAppleKey : _rcAndroidKey;
    final config = PurchasesConfiguration(key)
      ..appUserID = ApiService.userId; // Lie l'ID VoxLink à RevenueCat
    await Purchases.configure(config);
  } catch (_) {
    // Non bloquant — l'app fonctionne sans RevenueCat (fonctions free tier)
  }
}

class VoxLinkApp extends StatefulWidget {
  const VoxLinkApp({super.key});
  @override
  State<VoxLinkApp> createState() => _VoxLinkAppState();
}

class _VoxLinkAppState extends State<VoxLinkApp> {
  ThemeMode _themeMode = ThemeMode.light;
  void toggleTheme() => setState(() =>
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoxLink',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        primaryColor: const Color(0xFFFF6B00),
        colorScheme: const ColorScheme.light(primary: Color(0xFFFF6B00), secondary: Color(0xFF3797EF)),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF0F0F0F), elevation: 0.5),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B0C),
        primaryColor: const Color(0xFFFF6B00),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFFF6B00), secondary: Colors.white),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF111113), foregroundColor: Colors.white, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFF1C1C1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: ApiService.isAuthenticated
          ? MainNavigationFrame(toggleTheme: toggleTheme)
          : OnboardingView(onComplete: () => setState(() {})),
    );
  }
}

class MainNavigationFrame extends StatefulWidget {
  final VoidCallback toggleTheme;
  const MainNavigationFrame({super.key, required this.toggleTheme});
  @override
  State<MainNavigationFrame> createState() => _MainNavigationFrameState();
}

class _MainNavigationFrameState extends State<MainNavigationFrame> {
  int _currentIndex = 3;
  Map<String, dynamic> _profile = {};
  bool _profileLoaded = false;
  int _unreadMessages = 0;
  int _unreadCalls = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _connectWebSocket();
    _syncPremium();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await ApiService.getMyProfile();
      if (mounted) setState(() { _profile = p; _profileLoaded = true; });
    } catch (_) { if (mounted) setState(() => _profileLoaded = true); }
  }

  /// Sync RevenueCat → backend VoxLink à chaque démarrage
  Future<void> _syncPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final active = info.entitlements.active.containsKey(_rcEntitlement);
      if (active) {
        await ApiService.verifyPremium(info.originalAppUserId);
        if (mounted) _loadProfile();
      }
    } catch (_) {}
  }

  void _connectWebSocket() {
    final uid = ApiService.userId;
    if (uid == null) return;
    WebSocketService.instance.connect(uid);
    WebSocketService.instance.on('new_message', (data) {
      if (!mounted) return;
      if (_currentIndex != 3) {
        setState(() => _unreadMessages++);
        final msg = data['message'] as Map<String, dynamic>?;
        NotificationService.showMessageNotification(
          senderName: msg?['sender_id'] ?? 'Message', message: msg?['text'] ?? '');
      }
    });
    WebSocketService.instance.on('call_request', (data) {
      if (!mounted) return;
      if (_currentIndex != 2) setState(() => _unreadCalls++);
      final payload = data['payload'] as Map<String, dynamic>?;
      NotificationService.showCallNotification(callerName: payload?['caller_name'] ?? 'Appel entrant');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_profileLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))));
    }
    final views = [
      const HomeFeedView(),
      NetworkView(myUserId: ApiService.userId ?? ''),
      CallsView(profile: _profile),
      ChatView(profile: _profile, onMessagesRead: () { if (mounted) setState(() => _unreadMessages = 0); }),
      const GroupsView(),
      ProfileView(toggleTheme: widget.toggleTheme, profile: _profile, onProfileUpdated: _loadProfile),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: views),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF6B00),
        unselectedItemColor: Colors.grey[500],
        selectedFontSize: 8, unselectedFontSize: 8,
        onTap: (i) => setState(() {
          _currentIndex = i;
          if (i == 3) { _unreadMessages = 0; NotificationService.cancelAll(); }
          if (i == 2) _unreadCalls = 0;
        }),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 18), activeIcon: Icon(Icons.home, size: 18), label: 'Accueil'),
          const BottomNavigationBarItem(icon: Icon(Icons.people_outline, size: 18), activeIcon: Icon(Icons.people, size: 18), label: 'Réseau'),
          BottomNavigationBarItem(icon: _dot(Icons.phone_outlined, _unreadCalls), activeIcon: const Icon(Icons.phone, size: 18), label: 'Appels'),
          BottomNavigationBarItem(icon: _dot(Icons.chat_bubble_outline, _unreadMessages), activeIcon: const Icon(Icons.chat_bubble, size: 18), label: 'Messages'),
          const BottomNavigationBarItem(icon: Icon(Icons.public_outlined, size: 18), activeIcon: Icon(Icons.public, size: 18), label: 'Groupes'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 18), activeIcon: Icon(Icons.person, size: 18), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _dot(IconData icon, int count) => Stack(clipBehavior: Clip.none, children: [
    Icon(icon, size: 18),
    if (count > 0) Positioned(right: -3, top: -3, child: Container(
      width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF6B00), shape: BoxShape.circle))),
  ]);

  @override
  void dispose() { WebSocketService.instance.disconnect(); super.dispose(); }
}
