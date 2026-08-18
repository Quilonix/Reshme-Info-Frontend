import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/market_localizations.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(Locale) onLanguageChange;
  final VoidCallback onOnboardingComplete;

  const OnboardingScreen({
    super.key,
    required this.onLanguageChange,
    required this.onOnboardingComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedMarket = 'Ramanagara';
  String _selectedLanguage = 'kn';
  bool _isLoading = false;
  String? _errorMessage;

  List<String> _markets = [
    'Ramanagara',
    'Kollegala',
    'Sidlaghatta',
    'Vijayapura',
    'Kolar',
    'Chintamani',
    'Kanakapura',
    'Haveri',
    'Gubbi',
    'Santhemarahalli',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveMarkets();
  }

  Future<void> _fetchLiveMarkets() async {
    try {
      final data = await SupabaseConfig.client
          .from('markets')
          .select('name')
          .eq('is_active', true)
          .order('sort_order');
      if (data.isNotEmpty) {
        setState(() {
          _markets = data.map((m) => m['name'] as String).toList();
          if (!_markets.contains(_selectedMarket)) {
            _selectedMarket = _markets.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      // 1. Save / Update in Supabase app_users table with unique phone_number
      await SupabaseConfig.client.from('app_users').upsert(
        {
          'name': name,
          'phone_number': phone,
          'preferred_market': _selectedMarket,
        },
        onConflict: 'phone_number',
      );

      // 2. Persist in local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarded', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_preferred_market', _selectedMarket);

      // 3. Subscribe device to specific APMC market topic
      NotificationService.subscribeToMarket(_selectedMarket);

      AnalyticsService.logEvent(
        name: 'user_onboarded',
        parameters: {
          'preferred_market': _selectedMarket,
        },
      );

      widget.onOnboardingComplete();
    } catch (e) {
      debugPrint('Onboarding submission notice: $e');
      // Still allow entering app offline
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarded', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_preferred_market', _selectedMarket);
      widget.onOnboardingComplete();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKn = _selectedLanguage == 'kn';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/reshme_logo.png',
                  height: 72,
                  errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: AppTheme.primaryColor, size: 64),
                ),
                const SizedBox(height: 12),

                Text(
                  isKn ? 'ರೇಷ್ಮೆ ಮಾಹಿತಿ' : 'Reshme Info',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isKn ? 'ಕರ್ನಾಟಕ ರೇಷ್ಮೆ ಗೂಡು ಮಾರುಕಟ್ಟೆ ನೇರ ಹರಾಜು ದರಗಳು' : 'Real-Time Karnataka APMC Silk Cocoon Intelligence',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 28),

                // Language Selection Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isKn ? 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ / Select Language' : 'Select Language / ಭಾಷೆ',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLanguageOption(
                              label: 'ಕನ್ನಡ',
                              sub: 'Kannada',
                              langCode: 'kn',
                              isSelected: _selectedLanguage == 'kn',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLanguageOption(
                              label: 'English',
                              sub: 'English',
                              langCode: 'en',
                              isSelected: _selectedLanguage == 'en',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Farmer Details Form
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKn ? 'ರೈತರ ವಿವರಗಳು' : 'Farmer Details',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 14),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: isKn ? 'ನಿಮ್ಮ ಹೆಸರು (Farmer Name)' : 'Your Name',
                            prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF64748B)),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (isKn ? 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಹೆಸರನ್ನು ನಮೂದಿಸಿ' : 'Please enter your name')
                              : null,
                        ),

                        const SizedBox(height: 14),

                        // Phone Field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: isKn ? 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ (Mobile Number)' : 'Mobile Number',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF64748B)),
                          ),
                          validator: (v) => (v == null || v.trim().length < 10)
                              ? (isKn ? 'ಸರಿಯಾದ 10 ಅಂಕಿಗಳ ಮೊಬೈಲ್ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ' : 'Enter a valid 10-digit phone number')
                              : null,
                        ),

                        const SizedBox(height: 14),

                        // Preferred Market Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedMarket,
                          decoration: InputDecoration(
                            labelText: isKn ? 'ಮುಖ್ಯ ಮಾರುಕಟ್ಟೆ (Primary APMC Market)' : 'Primary APMC Market',
                            prefixIcon: const Icon(Icons.storefront_outlined, size: 20, color: Color(0xFF64748B)),
                          ),
                          items: _markets.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(MarketLocalizations.getMarketName(context, m)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMarket = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitOnboarding,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          isKn ? 'ಪ್ರಾರಂಭಿಸಿ (Explore Live Rates)' : 'Get Started',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String sub,
    required String langCode,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _selectedLanguage = langCode);
        widget.onLanguageChange(Locale(langCode));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
