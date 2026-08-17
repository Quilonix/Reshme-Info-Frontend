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
      // 1. Save / Update in Supabase app_users table using phone_number as unique key
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
      // If network fails, still allow offline entry and save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarded', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_preferred_market', _selectedMarket);

      NotificationService.subscribeToMarket(_selectedMarket);
      widget.onOnboardingComplete();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKn = _selectedLanguage == 'kn';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Logo & Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.grass_rounded,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'RESHME INFO',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        isKn ? 'ಕರ್ನಾಟಕ ರೇಷ್ಮೆ ಬೆಳೆಗಾರರ ವೇದಿಕೆ' : 'Karnataka Silk Farmers Portal',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 1. Language Selection (Large Tactile Buttons)
                Text(
                  isKn ? '1. ಭಾಷೆಯನ್ನು ಆಯ್ಕೆ ಮಾಡಿ' : '1. Select Your Language',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _LanguageCard(
                        title: 'ಕನ್ನಡ',
                        subtitle: 'Kannada',
                        isSelected: _selectedLanguage == 'kn',
                        onTap: () {
                          setState(() => _selectedLanguage = 'kn');
                          widget.onLanguageChange(const Locale('kn'));
                          AnalyticsService.logLanguageChange('kn');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LanguageCard(
                        title: 'English',
                        subtitle: 'ಇಂಗ್ಲಿಷ್',
                        isSelected: _selectedLanguage == 'en',
                        onTap: () {
                          setState(() => _selectedLanguage = 'en');
                          widget.onLanguageChange(const Locale('en'));
                          AnalyticsService.logLanguageChange('en');
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Farmer Details
                Text(
                  isKn ? '2. ರೈತರ ವಿವರ' : '2. Farmer Details',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: isKn ? 'ನಿಮ್ಮ ಹೆಸರು (Name)' : 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return isKn ? 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಹೆಸರನ್ನು ನಮೂದಿಸಿ' : 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: isKn ? 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ (Phone Number)' : 'Phone Number (10 digits)',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
                    counterText: '',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 10) {
                      return isKn ? '10 ಅಂಕಿಯ ಮೊಬೈಲ್ ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ' : 'Please enter 10 digit number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // 3. Preferred APMC Market
                Text(
                  isKn ? '3. ನಿಮ್ಮ ಹತ್ತಿರದ ರೇಷ್ಮೆ ಮಾರುಕಟ್ಟೆ' : '3. Preferred APMC Silk Market',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedMarket,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                      items: _markets.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            MarketLocalization.getLocalizedMarket(m, isKn),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMarket = val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitOnboarding,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isKn ? 'ಪ್ರಾರಂಭಿಸಿ (Get Started)' : 'Get Started',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorder,
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
