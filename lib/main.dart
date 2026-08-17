import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/supabase_config.dart';
import 'core/l10n/app_localizations.dart';
import 'core/services/analytics_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/market/presentation/market_screen.dart';
import 'features/stats/presentation/stats_screen.dart';
import 'features/info/presentation/info_screen.dart';
import 'features/notifications/presentation/notifications_screen.dart';
import 'features/about/presentation/about_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase Core
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase Core initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // 2. Initialize Supabase Client
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  // 3. Initialize FCM Notification Service & Request Permissions
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Notification initialization notice: $e');
  }

  // 4. Check onboarding & saved language state
  final prefs = await SharedPreferences.getInstance();
  final isOnboarded = prefs.getBool('is_onboarded') ?? false;
  final savedLang = prefs.getString('app_language') ?? 'kn';

  runApp(ReshmeInfoApp(
    initialIsOnboarded: isOnboarded,
    initialLanguage: savedLang,
  ));
}

class ReshmeInfoApp extends StatefulWidget {
  final bool initialIsOnboarded;
  final String initialLanguage;

  const ReshmeInfoApp({
    super.key,
    this.initialIsOnboarded = true,
    this.initialLanguage = 'kn',
  });

  @override
  State<ReshmeInfoApp> createState() => _ReshmeInfoAppState();
}

class _ReshmeInfoAppState extends State<ReshmeInfoApp> {
  late Locale _locale;
  late bool _isOnboarded;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLanguage);
    _isOnboarded = widget.initialIsOnboarded;
  }

  Future<void> _changeLanguage(Locale locale) async {
    setState(() {
      _locale = locale;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.languageCode);
  }

  void _completeOnboarding() {
    setState(() {
      _isOnboarded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reshme Info',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _locale,
      supportedLocales: const [
        Locale('kn', 'IN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _isOnboarded
          ? MainNavigationShell(onLanguageChange: _changeLanguage)
          : OnboardingScreen(
              onLanguageChange: _changeLanguage,
              onOnboardingComplete: _completeOnboarding,
            ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final Function(Locale) onLanguageChange;

  const MainNavigationShell({super.key, required this.onLanguageChange});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    const screenNames = ['HomeScreen', 'MarketScreen', 'StatsScreen', 'InfoScreen', 'AboutScreen'];
    if (index < screenNames.length) {
      AnalyticsService.logScreenView(screenNames[index]);
    }
  }

  void _toggleLanguage() {
    final currentLang = Localizations.localeOf(context).languageCode;
    final newLocale = currentLang == 'kn' ? const Locale('en') : const Locale('kn');
    widget.onLanguageChange(newLocale);
    AnalyticsService.logLanguageChange(newLocale.languageCode);
  }

  void _openNotifications() {
    AnalyticsService.logScreenView('NotificationsDedicatedScreen');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    final screens = [
      HomeScreen(
        onTabChange: _onTabSelected,
        onToggleLanguage: _toggleLanguage,
        onOpenNotifications: _openNotifications,
      ),
      MarketScreen(
        onToggleLanguage: _toggleLanguage,
        onOpenNotifications: _openNotifications,
      ),
      StatsScreen(
        onToggleLanguage: _toggleLanguage,
        onOpenNotifications: _openNotifications,
      ),
      InfoScreen(
        onToggleLanguage: _toggleLanguage,
        onOpenNotifications: _openNotifications,
      ),
      AboutScreen(
        onLanguageChange: widget.onLanguageChange,
        onToggleLanguage: _toggleLanguage,
        onOpenNotifications: _openNotifications,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.storefront_outlined),
            activeIcon: const Icon(Icons.storefront),
            label: l10n.translate('market'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart_outlined),
            activeIcon: const Icon(Icons.show_chart),
            label: l10n.translate('stats'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            activeIcon: const Icon(Icons.menu_book),
            label: l10n.translate('info'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            activeIcon: const Icon(Icons.info),
            label: l10n.translate('about'),
          ),
        ],
      ),
    );
  }
}
